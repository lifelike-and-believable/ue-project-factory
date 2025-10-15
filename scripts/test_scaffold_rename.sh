#!/usr/bin/env bash
# Test script to validate the rename logic in scaffold.sh matches new-plugin.yml
set -euo pipefail

# Create a temporary test directory with the expected template structure
TEST_DIR=$(mktemp -d)
echo "Testing scaffold.sh rename logic in: $TEST_DIR"

# Create the expected template structure (same as template repo)
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

# Create module source files
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

# Create Editor module files
cat > "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePluginEditor/SamplePluginEditor.cpp" << 'EOF'
#include "SamplePluginEditor.h"

#define LOCTEXT_NAMESPACE "FSamplePluginEditorModule"

void FSamplePluginEditorModule::StartupModule()
{
    // Startup code for SamplePluginEditor
}

void FSamplePluginEditorModule::ShutdownModule()
{
    // Shutdown code for SamplePluginEditor
}

#undef LOCTEXT_NAMESPACE

IMPLEMENT_MODULE(FSamplePluginEditorModule, SamplePluginEditor)
EOF

cat > "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePluginEditor/SamplePluginEditor.h" << 'EOF'
#pragma once

#include "CoreMinimal.h"
#include "Modules/ModuleManager.h"

class FSamplePluginEditorModule : public IModuleInterface
{
public:
    virtual void StartupModule() override;
    virtual void ShutdownModule() override;
};
EOF

cat > "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePluginEditor/SamplePluginEditor.Build.cs" << 'EOF'
using UnrealBuildTool;

public class SamplePluginEditor : ModuleRules
{
    public SamplePluginEditor(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = ModuleRules.PCHUsageMode.UseExplicitOrSharedPCHs;
    }
}
EOF

# Create Tests module files
cat > "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePluginTests/SamplePluginTests.cpp" << 'EOF'
#include "SamplePluginTests.h"

#define LOCTEXT_NAMESPACE "FSamplePluginTestsModule"

void FSamplePluginTestsModule::StartupModule()
{
    // Startup code for SamplePluginTests
}

void FSamplePluginTestsModule::ShutdownModule()
{
    // Shutdown code for SamplePluginTests
}

#undef LOCTEXT_NAMESPACE

IMPLEMENT_MODULE(FSamplePluginTestsModule, SamplePluginTests)
EOF

cat > "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePluginTests/SamplePluginTests.h" << 'EOF'
#pragma once

#include "CoreMinimal.h"
#include "Modules/ModuleManager.h"

class FSamplePluginTestsModule : public IModuleInterface
{
public:
    virtual void StartupModule() override;
    virtual void ShutdownModule() override;
};
EOF

cat > "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePluginTests/SamplePluginTests.Build.cs" << 'EOF'
using UnrealBuildTool;

public class SamplePluginTests : ModuleRules
{
    public SamplePluginTests(ReadOnlyTargetRules Target) : base(Target)
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

# Run the rename logic (extracted from scaffold.sh)
PLUGIN="MyAwesomePlugin"
UEVER="5.5"

echo "Renaming plugin from SamplePlugin to $PLUGIN for UE $UEVER"

# Replace all occurrences of SamplePlugin with the new plugin name in files first
# (before renaming, so git grep can find tracked files)
if git grep -l "SamplePlugin" > /dev/null; then
  git grep -l "SamplePlugin" | xargs sed -i "s/SamplePlugin/$PLUGIN/g"
fi

# Rename plugin folder
mv Plugins/SamplePlugin "Plugins/$PLUGIN"

# Rename module source files in each directory before renaming the directories
# This ensures files like SamplePlugin.cpp become PluginName.cpp
for module_dir in "Plugins/$PLUGIN/Source/SamplePlugin" "Plugins/$PLUGIN/Source/SamplePluginEditor" "Plugins/$PLUGIN/Source/SamplePluginTests"; do
  if [ -d "$module_dir" ]; then
    module_basename=$(basename "$module_dir")
    # Rename .cpp, .h, and .Build.cs files that match the module name
    for ext in cpp h Build.cs; do
      if [ -f "$module_dir/$module_basename.$ext" ]; then
        new_module_name=$(echo "$module_basename" | sed "s/SamplePlugin/$PLUGIN/g")
        mv "$module_dir/$module_basename.$ext" "$module_dir/$new_module_name.$ext"
      fi
    done
  fi
done

# Rename source folders
mv "Plugins/$PLUGIN/Source/SamplePlugin" "Plugins/$PLUGIN/Source/$PLUGIN"
mv "Plugins/$PLUGIN/Source/SamplePluginEditor" "Plugins/$PLUGIN/Source/${PLUGIN}Editor"
mv "Plugins/$PLUGIN/Source/SamplePluginTests" "Plugins/$PLUGIN/Source/${PLUGIN}Tests"

# Rename .uplugin file
mv "Plugins/$PLUGIN/SamplePlugin.uplugin" "Plugins/$PLUGIN/${PLUGIN}.uplugin"
sed -i "s/\"EngineAssociation\": \"5.6\"/\"EngineAssociation\": \"$UEVER\"/g" ProjectSandbox/ProjectSandbox.uproject

echo "✓ Plugin renamed successfully"

# Verify the rename was successful
echo ""
echo "Verification:"

# Check directories exist
if [ -d "Plugins/$PLUGIN" ]; then
  echo "✓ Plugin directory renamed: Plugins/$PLUGIN"
else
  echo "✗ Plugin directory NOT found: Plugins/$PLUGIN"
  exit 1
fi

if [ -d "Plugins/$PLUGIN/Source/$PLUGIN" ]; then
  echo "✓ Source directory renamed: Plugins/$PLUGIN/Source/$PLUGIN"
else
  echo "✗ Source directory NOT found: Plugins/$PLUGIN/Source/$PLUGIN"
  exit 1
fi

if [ -d "Plugins/$PLUGIN/Source/${PLUGIN}Editor" ]; then
  echo "✓ Editor directory renamed: Plugins/$PLUGIN/Source/${PLUGIN}Editor"
else
  echo "✗ Editor directory NOT found: Plugins/$PLUGIN/Source/${PLUGIN}Editor"
  exit 1
fi

if [ -d "Plugins/$PLUGIN/Source/${PLUGIN}Tests" ]; then
  echo "✓ Tests directory renamed: Plugins/$PLUGIN/Source/${PLUGIN}Tests"
else
  echo "✗ Tests directory NOT found: Plugins/$PLUGIN/Source/${PLUGIN}Tests"
  exit 1
fi

if [ -f "Plugins/$PLUGIN/${PLUGIN}.uplugin" ]; then
  echo "✓ .uplugin file renamed: Plugins/$PLUGIN/${PLUGIN}.uplugin"
else
  echo "✗ .uplugin file NOT found: Plugins/$PLUGIN/${PLUGIN}.uplugin"
  exit 1
fi

# Check file contents
if grep -q "MyAwesomePlugin" "Plugins/$PLUGIN/${PLUGIN}.uplugin"; then
  echo "✓ .uplugin file content updated"
else
  echo "✗ .uplugin file content NOT updated"
  exit 1
fi

# Check that ALL module source files were renamed for ALL modules
for module in "$PLUGIN" "${PLUGIN}Editor" "${PLUGIN}Tests"; do
  if [ -f "Plugins/$PLUGIN/Source/$module/$module.cpp" ]; then
    echo "✓ Module source file renamed: $module.cpp"
  else
    echo "✗ Module source file NOT renamed: $module.cpp"
    exit 1
  fi
  
  if [ -f "Plugins/$PLUGIN/Source/$module/$module.h" ]; then
    echo "✓ Module header file renamed: $module.h"
  else
    echo "✗ Module header file NOT renamed: $module.h"
    exit 1
  fi
  
  if [ -f "Plugins/$PLUGIN/Source/$module/$module.Build.cs" ]; then
    echo "✓ Module build file renamed: $module.Build.cs"
  else
    echo "✗ Module build file NOT renamed: $module.Build.cs"
    exit 1
  fi
  
  # Verify the content was also updated
  if grep -q "MyAwesomePlugin" "Plugins/$PLUGIN/Source/$module/$module.cpp"; then
    echo "✓ Module source file content updated: $module.cpp"
  else
    echo "✗ Module source file content NOT updated: $module.cpp"
    exit 1
  fi
done

# Verify old file names don't exist
if [ -f "Plugins/$PLUGIN/Source/$PLUGIN/SamplePlugin.cpp" ]; then
  echo "✗ Old source file still exists: SamplePlugin.cpp"
  exit 1
else
  echo "✓ Old source files removed"
fi

if grep -q "\"EngineAssociation\": \"5.5\"" "ProjectSandbox/ProjectSandbox.uproject"; then
  echo "✓ UE version updated in project file"
else
  echo "✗ UE version NOT updated in project file"
  exit 1
fi

if grep -q "MyAwesomePlugin" "ProjectSandbox/ProjectSandbox.uproject"; then
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
cd "$HOME"
rm -rf "$TEST_DIR"
echo "✓ Test directory cleaned up"
