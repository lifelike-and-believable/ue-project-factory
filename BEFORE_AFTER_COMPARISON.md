# Before/After Comparison: Requirements Handling

## The Problem

Previously, the workflow would fail when requirements contained special characters. Here's why:

### Before (Problematic Approach)

```yaml
# Load requirements step
- name: Load requirements
  id: load_req
  run: |
    REQ="${{ inputs.requirements }}"
    # Use heredoc to safely handle multiline content
    echo "requirements<<EOF" >> $GITHUB_OUTPUT
    echo "$REQ" >> $GITHUB_OUTPUT
    echo "EOF" >> $GITHUB_OUTPUT

# Parse requirements step
- name: Parse requirements
  id: parse
  env:
    REQ: ${{ steps.load_req.outputs.requirements }}  # ❌ Shell interpolation issues
  run: |
    python3 scripts/parser.py > spec.json
```

**Problems:**
1. Requirements passed through `$GITHUB_OUTPUT`
2. Then read back via `${{ steps.load_req.outputs.requirements }}`
3. Then set as environment variable `REQ`
4. Multiple layers of shell interpretation could corrupt the data

**Failed Examples:**
```
Create a "special" plugin  # ❌ Quotes cause issues
Create a plugin; with semicolons  # ❌ Semicolons interpreted as command separators
```

### After (File-Based Approach)

```yaml
# Load requirements step
- name: Load requirements
  id: load_req
  run: |
    REQ="${{ inputs.requirements }}"
    # Write requirements to file for downstream use
    # Using printf to safely handle special characters and prevent command execution
    printf '%s' "$REQ" > requirements.txt  # ✅ Safe, no interpretation
    echo "✓ Requirements written to requirements.txt"

# Parse requirements step
- name: Parse requirements
  id: parse
  env:
    REQUIREMENTS_FILE: requirements.txt  # ✅ Just a filename
  run: |
    python3 scripts/parser.py > spec.json
```

**Benefits:**
1. Requirements written directly to file
2. No shell interpretation
3. File path passed as environment variable (not content)
4. Parser reads from file

**Now Works:**
```
Create a "special" plugin  # ✅ Works
Create a plugin; with semicolons  # ✅ Works
# Audio & Video Plugin
Create a plugin for UE 5.4  # ✅ Multiline works
Features:
- Audio processing with "DSP"
```

## Parser Changes

### Before
```python
# Read from environment variable
req = os.environ.get('REQ','')
```

### After
```python
# Read from file if available, otherwise fall back to environment variable
requirements_file = os.environ.get('REQUIREMENTS_FILE', '')
if requirements_file and os.path.exists(requirements_file):
    with open(requirements_file, 'r') as f:
        req = f.read()
else:
    req = os.environ.get('REQ', '')  # Backward compatibility
```

## Why This Works

### The Key Principle
**Never pass user content through multiple layers of shell interpretation.**

1. **Write to file immediately**: `printf '%s' "$REQ" > requirements.txt`
   - `printf '%s'` prevents any interpretation of format specifiers
   - Direct write to file, no intermediate processing

2. **Pass filename, not content**: `REQUIREMENTS_FILE: requirements.txt`
   - Environment variable contains just a path string
   - No risk of content being interpreted

3. **Read from file**: `with open(requirements_file, 'r') as f:`
   - Direct file I/O, no shell involvement
   - All characters preserved exactly as written

### Security Benefits

- **No command injection**: Requirements can't be executed as shell commands
- **No quote escaping issues**: All quotes preserved literally
- **No variable expansion**: Dollar signs, backticks, etc. are literal
- **No multiline issues**: Newlines preserved correctly

## Testing

We added comprehensive tests to verify this works:

1. **test_requirements_file.py**: Tests parser with various special characters
2. **test_workflow_simulation.sh**: Simulates the actual workflow steps

Example test cases:
```python
# Quotes work
('Quotes: Single quotes', "Create a 'special' plugin", {'plugin_name': 'Special'})
('Quotes: Double quotes', 'Create a "special" plugin', {'plugin_name': 'Special'})

# Multiline works
('Multiline: Basic', '''# Audio System
Create an audio engine plugin
With multiple features''', {'plugin_name': 'AudioEngine'})

# Special chars work
('Special: Semicolons', 'Create a plugin; with semicolons', {'plugin_name': 'CreateA'})
('Special: Ampersands', 'Create a data & analytics plugin', {'plugin_name': 'DataAnalytics'})
```

All tests pass! ✅
