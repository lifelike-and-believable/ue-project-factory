#!/usr/bin/env bash
# Test script to validate the rename logic from the workflow
set -euo pipefail

# Create a temporary test directory with the expected template structure
TEST_DIR=$(mktemp -d)
echo "Testing rename logic in: $TEST_DIR"

# Create the expected template structure
mkdir -p "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePlugin"
mkdir -p "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePluginEditor"
mkdir -p "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePluginTests"
mkdir -p "$TEST_DIR/ProjectSandbox"

# Create test files with SamplePlugin references
cat > "$TEST_DIR/Plugins/SamplePlugin/SamplePlugin.uplugin" << 'EOF'
{
  "FileVersion": 3,
  "Version": 1,
  "VersionName": "1.0",
  "FriendlyName": "SamplePlugin",
  "Description": "A sample plugin",
  "Category": "Other",
  "CreatedBy": "Test",
  "CreatedByURL": "",
  "DocsURL": "",
  "MarketplaceURL": "",
  "SupportURL": "",
  "CanContainContent": true,
  "IsBetaVersion": false,
  "IsExperimentalVersion": false,
  "Installed": false,
  "Modules": [
    {
      "Name": "SamplePlugin",
      "Type": "Runtime",
      "LoadingPhase": "Default"
    }
  ]
}
EOF

cat > "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.cpp" << 'EOF'
#include "SamplePlugin.h"

#define LOCTEXT_NAMESPACE "FSamplePluginModule"

void FSamplePluginModule::StartupModule()
{
    // Startup code for SamplePlugin
}

void FSamplePluginModule::ShutdownModule()
{
    // Shutdown code for SamplePlugin
}

#undef LOCTEXT_NAMESPACE

IMPLEMENT_MODULE(FSamplePluginModule, SamplePlugin)
EOF

cat > "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.h" << 'EOF'
#pragma once

#include "CoreMinimal.h"
#include "Modules/ModuleManager.h"

class FSamplePluginModule : public IModuleInterface
{
public:
    virtual void StartupModule() override;
    virtual void ShutdownModule() override;
};
EOF

cat > "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.Build.cs" << 'EOF'
using UnrealBuildTool;

public class SamplePlugin : ModuleRules
{
    public SamplePlugin(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = ModuleRules.PCHUsageMode.UseExplicitOrSharedPCHs;
    }
}
EOF

cat > "$TEST_DIR/ProjectSandbox/ProjectSandbox.uproject" << 'EOF'
{
  "FileVersion": 3,
  "EngineAssociation": "5.6",
  "Category": "",
  "Description": "",
  "Plugins": [
    {
      "Name": "SamplePlugin",
      "Enabled": true
    }
  ]
}
EOF

# Initialize git repo
cd "$TEST_DIR"
git init
git config user.name "Test User"
git config user.email "test@example.com"
git add -A
git commit -m "Initial template structure"

# Run the rename logic (same as in the workflow)
PLUGIN_NAME="TestPlugin"
UE_VERSION="5.5"

echo "Renaming plugin from SamplePlugin to $PLUGIN_NAME for UE $UE_VERSION"

# Check if the expected template structure exists
if [ ! -d "Plugins/SamplePlugin" ]; then
  echo "Error: Expected template structure not found (Plugins/SamplePlugin missing)"
  exit 1
fi

# Replace all occurrences of SamplePlugin with the new plugin name in files first
# (before renaming, so git grep can find tracked files)
# Escape special characters in PLUGIN_NAME for use in sed replacement string
PLUGIN_NAME_ESCAPED=$(printf '%s\n' "$PLUGIN_NAME" | sed 's/[&/\]/\\&/g')

# Use -z and xargs -0 to handle filenames with special characters safely
if git grep -lz "SamplePlugin" 2>/dev/null | xargs -0 -r sed -i "s/SamplePlugin/$PLUGIN_NAME_ESCAPED/g"; then
  echo "✓ Replaced SamplePlugin references in file contents"
else
  echo "⚠ No SamplePlugin references found in tracked files (may be expected)"
fi

# Rename plugin folder
mv Plugins/SamplePlugin "Plugins/$PLUGIN_NAME"
echo "✓ Renamed plugin folder"

# Rename module source files in each directory before renaming the directories
# This ensures files like SamplePlugin.cpp become PluginName.cpp
for module_dir in "Plugins/$PLUGIN_NAME/Source/SamplePlugin" "Plugins/$PLUGIN_NAME/Source/SamplePluginEditor" "Plugins/$PLUGIN_NAME/Source/SamplePluginTests"; do
  if [ -d "$module_dir" ]; then
    module_basename=$(basename "$module_dir")
    # Rename .cpp, .h, and .Build.cs files that match the module name
    for ext in cpp h Build.cs; do
      if [ -f "$module_dir/$module_basename.$ext" ]; then
        new_module_name=$(echo "$module_basename" | sed "s/SamplePlugin/$PLUGIN_NAME_ESCAPED/g")
        mv "$module_dir/$module_basename.$ext" "$module_dir/$new_module_name.$ext"
        echo "✓ Renamed $module_basename.$ext to $new_module_name.$ext"
      fi
    done
  fi
done

# Rename source folders (only if they exist)
if [ -d "Plugins/$PLUGIN_NAME/Source/SamplePlugin" ]; then
  mv "Plugins/$PLUGIN_NAME/Source/SamplePlugin" "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME"
  echo "✓ Renamed source folder: SamplePlugin -> $PLUGIN_NAME"
fi

if [ -d "Plugins/$PLUGIN_NAME/Source/SamplePluginEditor" ]; then
  mv "Plugins/$PLUGIN_NAME/Source/SamplePluginEditor" "Plugins/$PLUGIN_NAME/Source/${PLUGIN_NAME}Editor"
  echo "✓ Renamed source folder: SamplePluginEditor -> ${PLUGIN_NAME}Editor"
fi

if [ -d "Plugins/$PLUGIN_NAME/Source/SamplePluginTests" ]; then
  mv "Plugins/$PLUGIN_NAME/Source/SamplePluginTests" "Plugins/$PLUGIN_NAME/Source/${PLUGIN_NAME}Tests"
  echo "✓ Renamed source folder: SamplePluginTests -> ${PLUGIN_NAME}Tests"
fi

# Rename .uplugin file (only if it exists)
if [ -f "Plugins/$PLUGIN_NAME/SamplePlugin.uplugin" ]; then
  mv "Plugins/$PLUGIN_NAME/SamplePlugin.uplugin" "Plugins/$PLUGIN_NAME/${PLUGIN_NAME}.uplugin"
  echo "✓ Renamed .uplugin file"
fi

# Update UE version in project file (only if it exists)
if [ -f "ProjectSandbox/ProjectSandbox.uproject" ]; then
  # Escape UE_VERSION for use in sed replacement string
  UE_VERSION_ESCAPED=$(printf '%s\n' "$UE_VERSION" | sed 's/[&/\]/\\&/g')
  sed -i "s/\"EngineAssociation\": \"5.6\"/\"EngineAssociation\": \"$UE_VERSION_ESCAPED\"/g" ProjectSandbox/ProjectSandbox.uproject
  echo "✓ Updated UE version in project file"
fi

echo "✓ Plugin renamed successfully"

# Verify the rename was successful
echo ""
echo "Verification:"

# Check directories exist
if [ -d "Plugins/$PLUGIN_NAME" ]; then
  echo "✓ Plugin directory renamed: Plugins/$PLUGIN_NAME"
else
  echo "✗ Plugin directory NOT found: Plugins/$PLUGIN_NAME"
  exit 1
fi

if [ -d "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME" ]; then
  echo "✓ Source directory renamed: Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME"
else
  echo "✗ Source directory NOT found: Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME"
  exit 1
fi

if [ -d "Plugins/$PLUGIN_NAME/Source/${PLUGIN_NAME}Editor" ]; then
  echo "✓ Editor directory renamed: Plugins/$PLUGIN_NAME/Source/${PLUGIN_NAME}Editor"
else
  echo "✗ Editor directory NOT found: Plugins/$PLUGIN_NAME/Source/${PLUGIN_NAME}Editor"
  exit 1
fi

if [ -d "Plugins/$PLUGIN_NAME/Source/${PLUGIN_NAME}Tests" ]; then
  echo "✓ Tests directory renamed: Plugins/$PLUGIN_NAME/Source/${PLUGIN_NAME}Tests"
else
  echo "✗ Tests directory NOT found: Plugins/$PLUGIN_NAME/Source/${PLUGIN_NAME}Tests"
  exit 1
fi

if [ -f "Plugins/$PLUGIN_NAME/${PLUGIN_NAME}.uplugin" ]; then
  echo "✓ .uplugin file renamed: Plugins/$PLUGIN_NAME/${PLUGIN_NAME}.uplugin"
else
  echo "✗ .uplugin file NOT found: Plugins/$PLUGIN_NAME/${PLUGIN_NAME}.uplugin"
  exit 1
fi

# Check file contents
if grep -q "TestPlugin" "Plugins/$PLUGIN_NAME/${PLUGIN_NAME}.uplugin"; then
  echo "✓ .uplugin file content updated"
else
  echo "✗ .uplugin file content NOT updated"
  exit 1
fi

# Check that module source files were renamed
if [ -f "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME/$PLUGIN_NAME.cpp" ]; then
  echo "✓ Module source file renamed: $PLUGIN_NAME.cpp"
else
  echo "✗ Module source file NOT renamed: $PLUGIN_NAME.cpp"
  exit 1
fi

# Verify the content was also updated
if grep -q "TestPlugin" "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME/$PLUGIN_NAME.cpp"; then
  echo "✓ Module source file content updated"
else
  echo "✗ Module source file content NOT updated"
  exit 1
fi

# Verify old file name doesn't exist
if [ -f "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME/SamplePlugin.cpp" ]; then
  echo "✗ Old source file still exists: SamplePlugin.cpp"
  exit 1
else
  echo "✓ Old source file removed"
fi

# Check that .h file was renamed
if [ -f "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME/$PLUGIN_NAME.h" ]; then
  echo "✓ Module header file renamed: $PLUGIN_NAME.h"
else
  echo "✗ Module header file NOT renamed: $PLUGIN_NAME.h"
  exit 1
fi

# Check that .Build.cs file was renamed
if [ -f "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME/$PLUGIN_NAME.Build.cs" ]; then
  echo "✓ Module build file renamed: $PLUGIN_NAME.Build.cs"
else
  echo "✗ Module build file NOT renamed: $PLUGIN_NAME.Build.cs"
  exit 1
fi

if grep -q "\"EngineAssociation\": \"5.5\"" "ProjectSandbox/ProjectSandbox.uproject"; then
  echo "✓ UE version updated in project file"
else
  echo "✗ UE version NOT updated in project file"
  exit 1
fi

if grep -q "TestPlugin" "ProjectSandbox/ProjectSandbox.uproject"; then
  echo "✓ Plugin name updated in project file"
else
  echo "✗ Plugin name NOT updated in project file"
  exit 1
fi

# Check that old name doesn't exist anywhere
if git grep -q "SamplePlugin" 2>/dev/null; then
  echo "✗ Old plugin name still found in files:"
  git grep "SamplePlugin"
  exit 1
else
  echo "✓ Old plugin name removed from all files"
fi

echo ""
echo "✓ All rename operations completed successfully!"

# Cleanup
cd /
rm -rf "$TEST_DIR"
echo "✓ Test directory cleaned up"
