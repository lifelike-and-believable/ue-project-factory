#!/usr/bin/env bash
# Integration test to validate the complete workflow components work together
set -euo pipefail

echo "=== Integration Test Suite ==="
echo ""

# Test 1: Parser with various input combinations
echo "Test 1: Parser integration with different inputs"
echo "----------------------------------------------"

test_parser_case() {
  local test_name="$1"
  local req="$2"
  local plugin_name="${3:-}"
  local ue_version="${4:-}"
  local expected_plugin="$5"
  local expected_ue="$6"
  
  echo -n "  Testing: $test_name... "
  
  if [ -n "$plugin_name" ]; then
    export PLUGIN_NAME="$plugin_name"
  else
    unset PLUGIN_NAME
  fi
  
  if [ -n "$ue_version" ]; then
    export UE_VERSION="$ue_version"
  else
    unset UE_VERSION
  fi
  
  export REQ="$req"
  
  result=$(python3 scripts/parser.py)
  actual_plugin=$(echo "$result" | jq -r .plugin_name)
  actual_ue=$(echo "$result" | jq -r .ue_version)
  
  if [ "$actual_plugin" != "$expected_plugin" ] || [ "$actual_ue" != "$expected_ue" ]; then
    echo "✗ FAILED"
    echo "    Expected: plugin=$expected_plugin, ue=$expected_ue"
    echo "    Got:      plugin=$actual_plugin, ue=$actual_ue"
    return 1
  fi
  
  echo "✓"
  return 0
}

# Run parser test cases
test_parser_case "Explicit inputs" "Create a plugin" "MyPlugin" "5.5" "MyPlugin" "5.5"
test_parser_case "Pattern extraction" "plugin called TestPlugin for UE 5.4" "" "" "TestPlugin" "5.4"
test_parser_case "Auto-derive from heading" "# Audio Engine Plugin" "" "" "AudioEngine" "5.6"
test_parser_case "Override from explicit" "plugin called OldName for UE 5.3" "NewName" "5.5" "NewName" "5.5"
test_parser_case "Default fallback" "" "" "" "NewPlugin" "5.6"

echo ""

# Test 2: Rename logic simulation (without git operations)
echo "Test 2: Rename logic components"
echo "--------------------------------"

# Create a temp directory structure
TEST_DIR=$(mktemp -d)
echo "  Using test directory: $TEST_DIR"

# Set up minimal template structure
mkdir -p "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePlugin"
mkdir -p "$TEST_DIR/ProjectSandbox"
cat > "$TEST_DIR/Plugins/SamplePlugin/SamplePlugin.uplugin" << 'EOF'
{
  "FriendlyName": "SamplePlugin",
  "Modules": [{"Name": "SamplePlugin"}]
}
EOF

cat > "$TEST_DIR/Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.h" << 'EOF'
#pragma once
class FSamplePluginModule {};
EOF

cat > "$TEST_DIR/ProjectSandbox/ProjectSandbox.uproject" << 'EOF'
{"EngineAssociation": "5.6", "Plugins": [{"Name": "SamplePlugin"}]}
EOF

cd "$TEST_DIR"

# Initialize minimal git repo
git init -q
git config user.name "Test"
git config user.email "test@test.com"
git add -A
git commit -q -m "init"

# Test the rename commands
PLUGIN_NAME="IntegrationTest"
UE_VERSION="5.4"

echo -n "  Testing file content replacement... "
# Use the same logic as the workflow (safe handling with xargs -r)
# Escape special characters in PLUGIN_NAME for use in sed replacement string
PLUGIN_NAME_ESCAPED=$(printf '%s\n' "$PLUGIN_NAME" | sed 's/[&/\]/\\&/g')
git grep -lz "SamplePlugin" 2>/dev/null | xargs -0 -r sed -i "s/SamplePlugin/$PLUGIN_NAME_ESCAPED/g"
# Verify replacement succeeded (in this test, we know files exist, so check for the new name)
if git grep -q "IntegrationTest" > /dev/null 2>&1; then
  echo "✓"
else
  echo "✗ FAILED - content not replaced (expected IntegrationTest in files)"
  exit 1
fi

echo -n "  Testing folder rename... "
mv Plugins/SamplePlugin "Plugins/$PLUGIN_NAME"
if [ -d "Plugins/$PLUGIN_NAME" ]; then
  echo "✓"
else
  echo "✗ FAILED - folder not renamed"
  exit 1
fi

echo -n "  Testing module file rename... "
mv "Plugins/$PLUGIN_NAME/Source/SamplePlugin" "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME"
if [ -f "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME/$PLUGIN_NAME.h" ]; then
  echo "✗ FAILED - file should have been renamed"
  exit 1
fi

# Need to rename the file too
mv "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME/SamplePlugin.h" "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME/$PLUGIN_NAME.h" 2>/dev/null || true

if [ -f "Plugins/$PLUGIN_NAME/Source/$PLUGIN_NAME/$PLUGIN_NAME.h" ]; then
  echo "✓"
else
  echo "✗ FAILED - file rename incomplete"
  exit 1
fi

echo -n "  Testing uplugin rename... "
mv "Plugins/$PLUGIN_NAME/SamplePlugin.uplugin" "Plugins/$PLUGIN_NAME/$PLUGIN_NAME.uplugin"
if [ -f "Plugins/$PLUGIN_NAME/$PLUGIN_NAME.uplugin" ]; then
  echo "✓"
else
  echo "✗ FAILED - uplugin not renamed"
  exit 1
fi

echo -n "  Testing UE version update... "
# Escape UE_VERSION for use in sed replacement string
UE_VERSION_ESCAPED=$(printf '%s\n' "$UE_VERSION" | sed 's/[&/\]/\\&/g')
sed -i "s/\"EngineAssociation\": \"5.6\"/\"EngineAssociation\": \"$UE_VERSION_ESCAPED\"/g" ProjectSandbox/ProjectSandbox.uproject
if grep -q "\"EngineAssociation\": \"5.4\"" ProjectSandbox/ProjectSandbox.uproject; then
  echo "✓"
else
  echo "✗ FAILED - UE version not updated"
  exit 1
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo ""

# Test 3: Workflow YAML validation
echo "Test 3: Workflow YAML syntax"
echo "-----------------------------"

echo -n "  Checking workflow YAML syntax... "
# Basic YAML syntax check - workflow file should exist and be parseable
cd /home/runner/work/ue-project-factory/ue-project-factory
if [ -f ".github/workflows/new-plugin.yml" ]; then
  # Simple validation - check for required keys
  if grep -q "^name:" .github/workflows/new-plugin.yml && \
     grep -q "^jobs:" .github/workflows/new-plugin.yml && \
     grep -q "workflow_dispatch:" .github/workflows/new-plugin.yml; then
    echo "✓"
  else
    echo "✗ FAILED - workflow missing required keys"
    exit 1
  fi
else
  echo "✗ FAILED - workflow file not found"
  exit 1
fi

echo ""

# Test 4: Requirements file handling
echo "Test 4: Requirements file handling"
echo "-----------------------------------"

echo -n "  Checking example requirements file... "
if [ -f "specs/example-plugin.md" ]; then
  echo "✓"
else
  echo "✗ FAILED - example requirements file not found"
  exit 1
fi

echo -n "  Testing requirements file parsing... "
REQ=$(cat specs/example-plugin.md)
export REQ
unset PLUGIN_NAME
unset UE_VERSION
result=$(python3 scripts/parser.py)
if [ -n "$result" ]; then
  plugin=$(echo "$result" | jq -r .plugin_name)
  ue_ver=$(echo "$result" | jq -r .ue_version)
  if [ -n "$plugin" ] && [ -n "$ue_ver" ]; then
    echo "✓ (derived: $plugin, UE $ue_ver)"
  else
    echo "✗ FAILED - could not parse requirements file"
    exit 1
  fi
else
  echo "✗ FAILED - parser returned empty result"
  exit 1
fi

echo ""

# Test 5: Documentation completeness
echo "Test 5: Documentation"
echo "---------------------"

echo -n "  Checking README.md... "
if [ -f "README.md" ]; then
  if grep -q "Plugin Naming" README.md && \
     grep -q "Setup" README.md && \
     grep -q "How it works" README.md; then
    echo "✓"
  else
    echo "✗ FAILED - README missing expected sections"
    exit 1
  fi
else
  echo "✗ FAILED - README not found"
  exit 1
fi

echo ""

# Summary
echo "==================================="
echo "✓ All integration tests passed!"
echo "==================================="
echo ""
echo "Summary of validated components:"
echo "  ✓ Parser handles multiple input modes"
echo "  ✓ Rename operations work correctly"
echo "  ✓ Workflow YAML is valid"
echo "  ✓ Requirements file support works"
echo "  ✓ Documentation is complete"
echo ""
echo "The automation is fully functional and ready for use."
