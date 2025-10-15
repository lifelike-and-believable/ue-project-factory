# Stub parser that turns requirements into a spec.json-like output.
import os, json, re

# Read requirements from file if REQUIREMENTS_FILE is set, otherwise from REQ env var
requirements_file = os.environ.get('REQUIREMENTS_FILE', '')
if requirements_file and os.path.exists(requirements_file):
    with open(requirements_file, 'r') as f:
        req = f.read()
else:
    req = os.environ.get('REQ', '')

name = os.environ.get('PLUGIN_NAME', '').strip()
ue_version_input = os.environ.get('UE_VERSION', '').strip()
ue_version = ue_version_input if ue_version_input else '5.6'  # Default version

def to_pascal_case(text):
    """Convert text to PascalCase alphanumeric"""
    # Replace hyphens and underscores with spaces to treat them as word separators
    text = text.replace('-', ' ').replace('_', ' ')
    # Remove all non-alphanumeric characters except spaces
    cleaned = re.sub(r'[^a-zA-Z0-9\s]', '', text)
    # Split on whitespace and capitalize each word
    words = cleaned.split()
    # Join and capitalize first letter of each word
    pascal = ''.join(word.capitalize() for word in words if word)
    return pascal

def derive_plugin_name(requirements):
    """Derive a deterministic plugin name from requirements"""
    if not requirements:
        return 'NewPlugin'
    
    # Try to extract a title or summary from the first line or heading
    lines = requirements.strip().split('\n')
    first_line = lines[0].strip() if lines else ''
    
    # Remove markdown heading markers
    first_line = re.sub(r'^#+\s*', '', first_line)
    
    # Try to extract from common patterns like "create a X plugin" or "X plugin"
    patterns = [
        r'create\s+(?:a|an)\s+([^.!?\n]+?)\s+plugin',
        r'build\s+(?:a|an)\s+([^.!?\n]+?)\s+plugin',
        r'implement\s+(?:a|an)\s+([^.!?\n]+?)\s+plugin',
        r'^([^.!?\n]+?)\s+plugin',
    ]
    
    for pattern in patterns:
        m = re.search(pattern, requirements, re.I | re.MULTILINE)
        if m:
            candidate = to_pascal_case(m.group(1))
            if candidate and re.match(r'^[A-Z][A-Za-z0-9]*$', candidate):
                return candidate
    
    # Try using the first line/title
    candidate = to_pascal_case(first_line)
    if candidate and re.match(r'^[A-Z][A-Za-z0-9]*$', candidate):
        # Limit length to reasonable size (e.g., 50 chars)
        return candidate[:50] if len(candidate) > 50 else candidate
    
    # Fallback
    return 'NewPlugin'

# Extract plugin name
if not name:
    # Try to extract from requirements using "plugin called X" pattern
    m = re.search(r'plugin\s+called\s+([A-Za-z0-9_-]+)', req, re.I)
    if m: 
        candidate = m.group(1)
        # If already valid PascalCase, keep it; otherwise convert
        if re.match(r'^[A-Z][A-Za-z0-9]*$', candidate):
            name = candidate
        else:
            # Clean up the extracted name (remove hyphens, underscores)
            name = to_pascal_case(candidate)
    else:
        # Derive from requirements
        name = derive_plugin_name(req)

# Validate plugin name
if not name or not re.match(r'^[A-Z][A-Za-z0-9]*$', name):
    # Invalid name, use fallback
    name = 'NewPlugin'

# Extract UE version if mentioned (e.g., "UE 5.5", "UE5.4", "Unreal Engine 5.3", etc.)
# Only override if not already set from input
if not ue_version_input:
    ue_match = re.search(r'(?:UE|Unreal\s+Engine)\s*(\d+\.\d+)', req, re.I)
    if ue_match:
        ue_version = ue_match.group(1)

spec = {'plugin_name': name, 'description': 'Generated from requirements', 'ue_version': ue_version, 'targets': ['Win64'], 'include_gauntlet': True}
print(json.dumps(spec))
