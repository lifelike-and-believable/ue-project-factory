# Requirements Handling Fix - Changelog

## Problem
The workflow previously failed when the `requirements` input contained:
- Quote marks (single or double)
- Multiline content
- Special shell characters (semicolons, pipes, ampersands, etc.)

This was because requirements were passed through GitHub Actions outputs and then set as environment variables, which could cause shell interpolation issues.

Reference: https://github.com/lifelike-and-believable/ue-project-factory/actions/runs/18538966257/job/52841315386

## Solution
Changed the workflow to use a file-based approach:

1. **Load requirements step**: Now writes requirements to `requirements.txt` using `printf` (safe for all characters)
2. **Parse requirements step**: Sets `REQUIREMENTS_FILE` environment variable instead of passing content directly
3. **Parser script**: Reads from `requirements.txt` file instead of `REQ` environment variable
4. **Create issue step**: Reads requirements from file using `cat requirements.txt`

## Benefits
- ✅ No shell interpolation - requirements are never executed as commands
- ✅ Safe handling of quotes, multiline content, and special characters
- ✅ Backward compatible - parser still supports `REQ` environment variable for existing tests
- ✅ Simpler debugging - requirements.txt is available for inspection

## Changes Made

### `.github/workflows/new-plugin.yml`
- **Load requirements step** (lines 55-76): Changed from writing to `$GITHUB_OUTPUT` to writing to `requirements.txt` file
- **Parse requirements step** (lines 77-91): Changed from setting `REQ` env var to setting `REQUIREMENTS_FILE` env var
- **Create issue step** (line 314): Changed from reading GitHub output to reading from file

### `scripts/parser.py`
- Added logic to read from `REQUIREMENTS_FILE` if set, otherwise fall back to `REQ` env var for backward compatibility

### New Tests
- `scripts/test_requirements_file.py`: Comprehensive tests for quoted and multiline requirements
- `scripts/test_workflow_simulation.sh`: End-to-end workflow simulation tests

## Testing
All test suites pass (5/5):
1. Parser Unit Tests (18/18 tests)
2. Requirements File Handling Tests (12/12 tests) - NEW
3. Rename Logic Tests
4. Workflow Simulation Tests (5/5 tests) - NEW
5. Integration Tests

## Examples of Now-Supported Requirements

### Quoted requirements:
```
Create a "special" plugin with 'advanced' features
```

### Multiline requirements:
```
# Audio System Plugin
Create an audio engine plugin
With multiple features:
- Feature 1
- Feature 2
```

### Special characters:
```
Create a data & analytics plugin for networking | communication
```

All of these now work correctly without errors or command injection risks.
