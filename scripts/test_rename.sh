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
if git grep -l "SamplePlugin" > /dev/null; then
  git grep -l "SamplePlugin" | xargs sed -i "s/SamplePlugin/$PLUGIN_NAME/g"
fi

# Rename plugin folder
mv Plugins/SamplePlugin "Plugins/$PLUGIN_NAME"

# Rename source folders
mv "Plugins/$PLUGIN_NAME/Source/SamplePlugin" "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME"
mv "Plugins/$PLUGIN_NAME/Source/SamplePluginEditor" "Plugins/$PLUGIN_NAME/Source/${PLUGIN_NAME}Editor"
mv "Plugins/$PLUGIN_NAME/Source/SamplePluginTests" "Plugins/$PLUGIN_NAME/Source/${PLUGIN_NAME}Tests"

# Rename .uplugin file
mv "Plugins/$PLUGIN_NAME/SamplePlugin.uplugin" "Plugins/$PLUGIN_NAME/${PLUGIN_NAME}.uplugin"

# Update UE version in project file
sed -i "s/\"EngineAssociation\": \"5.6\"/\"EngineAssociation\": \"$UE_VERSION\"/g" ProjectSandbox/ProjectSandbox.uproject

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

# Note: Individual .cpp/.h files are not renamed, only their content is updated.
# This is normal - UE plugins can have files with various names.
if grep -q "TestPlugin" "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME/SamplePlugin.cpp"; then
  echo "✓ Source file content updated (file name unchanged, which is expected for UE plugin source files)"
else
  echo "✗ Source file content NOT updated"
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
