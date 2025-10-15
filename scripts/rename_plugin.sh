#!/usr/bin/env bash
# Standalone script to rename SamplePlugin to a new plugin name
# Usage: ./rename_plugin.sh <PluginName> [UE_Version]

set -euo pipefail

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <PluginName> [UE_Version]"
    echo "Example: $0 MyAwesomePlugin 5.5"
    exit 1
fi

PLUGIN_NAME="$1"
UE_VERSION="${2:-5.6}"

# Validate plugin name (should be PascalCase alphanumeric)
if ! [[ "$PLUGIN_NAME" =~ ^[A-Z][A-Za-z0-9]*$ ]]; then
    echo "Error: Plugin name must be PascalCase alphanumeric (e.g., MyPlugin, not my-plugin or myPlugin)"
    echo "Invalid name: $PLUGIN_NAME"
    exit 1
fi

# Validate UE version (should be X.Y format)
if ! [[ "$UE_VERSION" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo "Error: UE version must be in X.Y format (e.g., 5.6)"
    echo "Invalid version: $UE_VERSION"
    exit 1
fi

echo "Renaming plugin from SamplePlugin to $PLUGIN_NAME for UE $UE_VERSION"

# Check if we're in a valid Unreal plugin project
if [ ! -d "Plugins/SamplePlugin" ]; then
    echo "Error: Expected template structure not found (Plugins/SamplePlugin missing)"
    echo "This script should be run in the root of a project created from ue-plugin-template"
    echo "Current directory: $(pwd)"
    exit 1
fi

# Backup function (optional, can be enabled for safety)
backup_enabled=false
if [ "$backup_enabled" = true ]; then
    BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
    echo "Creating backup in $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    cp -r Plugins/SamplePlugin "$BACKUP_DIR/"
    if [ -f "ProjectSandbox/ProjectSandbox.uproject" ]; then
        cp "ProjectSandbox/ProjectSandbox.uproject" "$BACKUP_DIR/"
    fi
    echo "✓ Backup created"
fi

# Step 1: Replace all text content first (before renaming files/folders)
echo "Step 1: Updating file contents..."

# Use find instead of git grep to work even outside git repos
find . -type f \( -name "*.cpp" -o -name "*.h" -o -name "*.cs" -o -name "*.uplugin" -o -name "*.uproject" \) \
    -not -path "./backup_*" \
    -exec grep -l "SamplePlugin" {} \; 2>/dev/null | while read -r file; do
    echo "  Updating: $file"
    sed -i "s/SamplePlugin/$PLUGIN_NAME/g" "$file"
done

echo "✓ File contents updated"

# Step 2: Rename source files within each module directory
echo "Step 2: Renaming source files..."

for module_dir in "Plugins/SamplePlugin/Source/SamplePlugin" "Plugins/SamplePlugin/Source/SamplePluginEditor" "Plugins/SamplePlugin/Source/SamplePluginTests"; do
    if [ -d "$module_dir" ]; then
        module_basename=$(basename "$module_dir")
        echo "  Processing module: $module_basename"
        
        # Rename .cpp, .h, and .Build.cs files that match the module name
        for ext in cpp h Build.cs; do
            old_file="$module_dir/$module_basename.$ext"
            if [ -f "$old_file" ]; then
                new_module_name=$(echo "$module_basename" | sed "s/SamplePlugin/$PLUGIN_NAME/g")
                new_file="$module_dir/$new_module_name.$ext"
                echo "    Renaming: $old_file -> $new_file"
                mv "$old_file" "$new_file"
            fi
        done
    fi
done

echo "✓ Source files renamed"

# Step 3: Rename directories
echo "Step 3: Renaming directories..."

# Rename source module directories
if [ -d "Plugins/SamplePlugin/Source/SamplePlugin" ]; then
    echo "  Renaming: Plugins/SamplePlugin/Source/SamplePlugin -> Plugins/SamplePlugin/Source/$PLUGIN_NAME"
    mv "Plugins/SamplePlugin/Source/SamplePlugin" "Plugins/SamplePlugin/Source/$PLUGIN_NAME"
fi

if [ -d "Plugins/SamplePlugin/Source/SamplePluginEditor" ]; then
    echo "  Renaming: Plugins/SamplePlugin/Source/SamplePluginEditor -> Plugins/SamplePlugin/Source/${PLUGIN_NAME}Editor"
    mv "Plugins/SamplePlugin/Source/SamplePluginEditor" "Plugins/SamplePlugin/Source/${PLUGIN_NAME}Editor"
fi

if [ -d "Plugins/SamplePlugin/Source/SamplePluginTests" ]; then
    echo "  Renaming: Plugins/SamplePlugin/Source/SamplePluginTests -> Plugins/SamplePlugin/Source/${PLUGIN_NAME}Tests"
    mv "Plugins/SamplePlugin/Source/SamplePluginTests" "Plugins/SamplePlugin/Source/${PLUGIN_NAME}Tests"
fi

echo "✓ Module directories renamed"

# Step 4: Rename .uplugin file
echo "Step 4: Renaming .uplugin file..."
if [ -f "Plugins/SamplePlugin/SamplePlugin.uplugin" ]; then
    echo "  Renaming: Plugins/SamplePlugin/SamplePlugin.uplugin -> Plugins/SamplePlugin/${PLUGIN_NAME}.uplugin"
    mv "Plugins/SamplePlugin/SamplePlugin.uplugin" "Plugins/SamplePlugin/${PLUGIN_NAME}.uplugin"
fi

echo "✓ .uplugin file renamed"

# Step 5: Rename main plugin directory
echo "Step 5: Renaming main plugin directory..."
echo "  Renaming: Plugins/SamplePlugin -> Plugins/$PLUGIN_NAME"
mv "Plugins/SamplePlugin" "Plugins/$PLUGIN_NAME"

echo "✓ Main plugin directory renamed"

# Step 6: Update UE version in project file
echo "Step 6: Updating UE version in project file..."
if [ -f "ProjectSandbox/ProjectSandbox.uproject" ]; then
    echo "  Updating UE version from default to $UE_VERSION"
    sed -i "s/\"EngineAssociation\": \"[0-9]\+\.[0-9]\+\"/\"EngineAssociation\": \"$UE_VERSION\"/g" ProjectSandbox/ProjectSandbox.uproject
    echo "✓ Project file updated"
else
    echo "  Warning: ProjectSandbox/ProjectSandbox.uproject not found, skipping UE version update"
fi

# Final verification
echo ""
echo "Verification:"

# Check that key files/directories exist
checks=(
    "Plugins/$PLUGIN_NAME"
    "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME"
    "Plugins/$PLUGIN_NAME/Source/${PLUGIN_NAME}Editor"  
    "Plugins/$PLUGIN_NAME/Source/${PLUGIN_NAME}Tests"
    "Plugins/$PLUGIN_NAME/${PLUGIN_NAME}.uplugin"
    "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME/${PLUGIN_NAME}.cpp"
    "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME/${PLUGIN_NAME}.h"
    "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME/${PLUGIN_NAME}.Build.cs"
)

all_good=true
for check in "${checks[@]}"; do
    if [ -e "$check" ]; then
        echo "✓ $check"
    else
        echo "✗ $check (missing)"
        all_good=false
    fi
done

# Check that old references are gone
remaining_files=$(find . -type f \( -name "*.cpp" -o -name "*.h" -o -name "*.cs" -o -name "*.uplugin" -o -name "*.uproject" \) \
    -not -path "./backup_*" \
    -exec grep -l "SamplePlugin" {} \; 2>/dev/null || true)

if [ -n "$remaining_files" ]; then
    echo "✗ Old SamplePlugin references still found in:"
    echo "$remaining_files"
    
    # Show the actual problematic lines for debugging
    echo ""
    echo "Problematic lines:"
    echo "$remaining_files" | while read -r file; do
        if [ -f "$file" ]; then
            echo "In $file:"
            grep -n "SamplePlugin" "$file" 2>/dev/null || true
            echo ""
        fi
    done
    all_good=false
else
    echo "✓ No old SamplePlugin references found"
fi

echo ""
if [ "$all_good" = true ]; then
    echo "🎉 Plugin successfully renamed from SamplePlugin to $PLUGIN_NAME!"
    echo "   UE Version: $UE_VERSION"
    echo "   Location: Plugins/$PLUGIN_NAME"
else
    echo "❌ Some issues were found. Please review the output above."
    exit 1
fi