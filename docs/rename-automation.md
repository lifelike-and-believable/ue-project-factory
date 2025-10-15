# UE Plugin Factory - Rename Automation

This document explains how the UE Plugin Factory automatically renames plugins from the template structure to use a custom plugin name.

## Overview

The factory workflow creates repositories from the [ue-plugin-template](https://github.com/lifelike-and-believable/ue-plugin-template) and automatically renames all "SamplePlugin" references to the desired plugin name.

## Process Flow

1. **Repository Creation**: New repo created from template using GitHub CLI
2. **Plugin Name Resolution**: Requirements parsed to extract or derive plugin name  
3. **Automated Rename**: All files, folders, and content updated with new plugin name
4. **Commit & Push**: Changes committed to main branch
5. **Issue Creation**: Copilot agent assigned to implement plugin functionality

## Rename Operations

### Files & Folders Renamed
- `Plugins/SamplePlugin/` → `Plugins/{PluginName}/`
- `Source/SamplePlugin/` → `Source/{PluginName}/`
- `Source/SamplePluginEditor/` → `Source/{PluginName}Editor/`
- `Source/SamplePluginTests/` → `Source/{PluginName}Tests/`
- `SamplePlugin.uplugin` → `{PluginName}.uplugin`
- `SamplePlugin.cpp` → `{PluginName}.cpp`
- `SamplePlugin.h` → `{PluginName}.h`  
- `SamplePlugin.Build.cs` → `{PluginName}.Build.cs`
- Similar for Editor and Tests modules

### Content Updated
All file contents are searched and replaced:
- Class names: `FSamplePluginModule` → `F{PluginName}Module`
- Module references: `SamplePlugin` → `{PluginName}` 
- Log messages and comments
- Build dependencies
- .uplugin metadata
- Project file plugin references

### UE Version Update
- `ProjectSandbox.uproject` EngineAssociation updated to target UE version

## Scripts

### Current Workflow (new-plugin.yml)
The GitHub workflow includes inline rename logic that:
- Uses `git grep` to find files containing "SamplePlugin" 
- Updates content with `sed` before renaming files
- Renames files and directories systematically
- Validates the rename was successful

### Standalone Script (rename_plugin.sh)
A standalone script for testing and manual use:
```bash
./scripts/rename_plugin.sh MyAwesomePlugin 5.5
```

Features:
- Works outside git repositories (uses `find` instead of `git grep`)
- Comprehensive validation and error reporting
- Step-by-step progress output
- Detailed verification checks

## Plugin Name Requirements

Plugin names must be:
- **PascalCase** (e.g., `MyAwesomePlugin`, not `myAwesomePlugin`)
- **Alphanumeric only** (no hyphens, underscores, spaces)
- **Valid C++ identifier** (starts with letter)

The parser automatically converts common formats:
- `my-awesome-plugin` → `MyAwesomePlugin`
- `UI_Helper` → `UiHelper`
- `aiNavigation` → `AiNavigation`

## Testing

### Automated Tests
- `scripts/test_rename.sh` - Tests workflow logic
- `scripts/test_standalone_rename.sh` - Tests standalone script  
- `scripts/test_parser.py` - Tests requirement parsing

### Manual Testing
Run tests locally:
```bash
./scripts/test_rename.sh
./scripts/test_standalone_rename.sh
python3 scripts/test_parser.py
```

## Workflow Usage

### Via GitHub UI
1. Go to Actions → New UE Plugin Project
2. Fill in plugin requirements or requirements file
3. Optionally specify plugin name and UE version
4. Run workflow

### Via Requirements File
Create a spec file (e.g., `specs/my-plugin.md`):
```markdown
# My Awesome Plugin

Create a plugin called MyAwesomePlugin for UE 5.5 that provides...
```

Use in workflow:
- **requirements_file**: `specs/my-plugin.md`

### Via Direct Input
- **plugin_name**: `MyAwesomePlugin` (optional, will be derived if blank)
- **ue_version**: `5.5` (optional, defaults to 5.6)
- **requirements**: Direct text input of what the plugin should do

## Error Handling

The rename process includes validation:
- Verifies template structure exists
- Checks all expected files/folders are created
- Confirms no old references remain
- Validates plugin name format
- Reports detailed errors if issues occur

## Future Enhancements

Potential improvements:
- Support for custom module structures
- Blueprint-only plugins  
- Multi-target platform configuration
- Custom template repositories
- Batch plugin creation