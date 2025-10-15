#!/usr/bin/env bash
# Test the standalone rename_plugin.sh script
set -euo pipefail

# Create a temporary test directory with the expected template structure
TEST_DIR=$(mktemp -d)
echo "Testing rename_plugin.sh script in: $TEST_DIR"

# Create the expected template structure (more comprehensive than before)
mkdir -p "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePlugin"
mkdir -p "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePluginEditor"
mkdir -p "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePluginTests"
mkdir -p "$TEST_DIR/Plugins/SamplePlugin/Content"
mkdir -p "$TEST_DIR/ProjectSandbox"

# Create test files with SamplePlugin references
cat > "$TEST_DIR/Plugins/SamplePlugin/SamplePlugin.uplugin" << 'EOF'
{
  "FileVersion": 3,
  "Version": 1,
  "VersionName": "1.0",
  "FriendlyName": "SamplePlugin",
  "Description": "A sample plugin for SamplePlugin functionality",
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
    },
    {
      "Name": "SamplePluginEditor",
      "Type": "Editor",
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
    UE_LOG(LogTemp, Warning, TEXT("SamplePlugin module started"));
}

void FSamplePluginModule::ShutdownModule()
{
    // Shutdown code for SamplePlugin
    UE_LOG(LogTemp, Warning, TEXT("SamplePlugin module shutdown"));
}

#undef LOCTEXT_NAMESPACE

IMPLEMENT_MODULE(FSamplePluginModule, SamplePlugin)
EOF

cat > "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.h" << 'EOF'
#pragma once

#include "CoreMinimal.h"
#include "Modules/ModuleManager.h"

/**
 * The main module for SamplePlugin functionality
 */
class FSamplePluginModule : public IModuleInterface
{
public:
    /** Called when the SamplePlugin module is loaded */
    virtual void StartupModule() override;
    
    /** Called when the SamplePlugin module is unloaded */
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
        
        PublicDependencyModuleNames.AddRange(
            new string[]
            {
                "Core",
                // Add other SamplePlugin dependencies here
            }
        );
        
        PrivateDependencyModuleNames.AddRange(
            new string[]
            {
                "CoreUObject",
                "Engine",
                // Add other SamplePlugin private dependencies
            }
        );
    }
}
EOF

# Create Editor module files
cat > "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePluginEditor/SamplePluginEditor.cpp" << 'EOF'
#include "SamplePluginEditor.h"
#include "SamplePlugin.h"

#define LOCTEXT_NAMESPACE "FSamplePluginEditorModule"

void FSamplePluginEditorModule::StartupModule()
{
    // Initialize SamplePluginEditor
}

void FSamplePluginEditorModule::ShutdownModule()
{
    // Cleanup SamplePluginEditor
}

#undef LOCTEXT_NAMESPACE

IMPLEMENT_MODULE(FSamplePluginEditorModule, SamplePluginEditor)
EOF

cat > "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePluginEditor/SamplePluginEditor.h" << 'EOF'
#pragma once

#include "CoreMinimal.h"
#include "Modules/ModuleManager.h"

/**
 * Editor module for SamplePlugin
 */
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
        
        PublicDependencyModuleNames.AddRange(
            new string[]
            {
                "Core",
                "SamplePlugin"
            }
        );
        
        PrivateDependencyModuleNames.AddRange(
            new string[]
            {
                "CoreUObject",
                "Engine",
                "UnrealEd"
            }
        );
    }
}
EOF

# Create Tests module files
cat > "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePluginTests/SamplePluginTests.cpp" << 'EOF'
#include "SamplePluginTests.h"

#define LOCTEXT_NAMESPACE "FSamplePluginTestsModule"

void FSamplePluginTestsModule::StartupModule()
{
    // Initialize SamplePlugin tests
}

void FSamplePluginTestsModule::ShutdownModule()
{
    // Cleanup SamplePlugin tests
}

#undef LOCTEXT_NAMESPACE

IMPLEMENT_MODULE(FSamplePluginTestsModule, SamplePluginTests)
EOF

cat > "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePluginTests/SamplePluginTests.h" << 'EOF'
#pragma once

#include "CoreMinimal.h"
#include "Modules/ModuleManager.h"

/**
 * Test module for SamplePlugin
 */
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
        
        PublicDependencyModuleNames.AddRange(
            new string[]
            {
                "Core",
                "SamplePlugin"
            }
        );
        
        PrivateDependencyModuleNames.AddRange(
            new string[]
            {
                "CoreUObject",
                "Engine"
            }
        );
    }
}
EOF

cat > "$TEST_DIR/ProjectSandbox/ProjectSandbox.uproject" << 'EOF'
{
  "FileVersion": 3,
  "EngineAssociation": "5.6",
  "Category": "",
  "Description": "Test project for SamplePlugin",
  "Plugins": [
    {
      "Name": "SamplePlugin",
      "Enabled": true
    }
  ]
}
EOF

# Test the rename script
cd "$TEST_DIR"
echo "Running rename script..."
/workspaces/ue-project-factory/scripts/rename_plugin.sh "AwesomePlugin" "5.4"

echo ""
echo "✓ Rename script completed successfully!"

# Cleanup
cd /
rm -rf "$TEST_DIR"
echo "✓ Test directory cleaned up"
echo ""
echo "🎉 Standalone rename script test passed!"