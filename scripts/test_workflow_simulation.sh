#!/usr/bin/env bash
# Simulate the workflow steps to verify requirements file handling works end-to-end
set -euo pipefail

echo "=== Workflow Simulation Test ==="
echo ""

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Copy parser to test directory
cp /home/runner/work/ue-project-factory/ue-project-factory/scripts/parser.py .

echo "Test 1: Inline requirements with quotes"
echo "----------------------------------------"
# Simulate "Load requirements" step with quoted content
REQ='Create a "special" plugin called QuotePlugin for UE 5.5'
printf '%s' "$REQ" > requirements.txt
echo "✓ Requirements written to requirements.txt"

# Simulate "Parse requirements" step
export REQUIREMENTS_FILE=requirements.txt
export PLUGIN_NAME=""
export UE_VERSION=""
python3 parser.py > spec.json
PLUGIN_NAME=$(jq -r .plugin_name spec.json)
UE_VERSION=$(jq -r .ue_version spec.json)
echo "✓ Resolved plugin name: $PLUGIN_NAME"
echo "✓ Resolved UE version: $UE_VERSION"

if [ "$PLUGIN_NAME" != "QuotePlugin" ]; then
  echo "✗ Expected plugin name: QuotePlugin, got: $PLUGIN_NAME"
  exit 1
fi
if [ "$UE_VERSION" != "5.5" ]; then
  echo "✗ Expected UE version: 5.5, got: $UE_VERSION"
  exit 1
fi
echo ""

echo "Test 2: Multiline requirements with special characters"
echo "-------------------------------------------------------"
REQ='# Audio & Video Plugin
Create a plugin for UE 5.4
Features:
- Audio processing with "DSP"
- Video encoding/decoding
- Real-time effects'
printf '%s' "$REQ" > requirements.txt
echo "✓ Requirements written to requirements.txt"

export REQUIREMENTS_FILE=requirements.txt
export PLUGIN_NAME=""
export UE_VERSION=""
python3 parser.py > spec.json
PLUGIN_NAME=$(jq -r .plugin_name spec.json)
UE_VERSION=$(jq -r .ue_version spec.json)
echo "✓ Resolved plugin name: $PLUGIN_NAME"
echo "✓ Resolved UE version: $UE_VERSION"

if [ "$UE_VERSION" != "5.4" ]; then
  echo "✗ Expected UE version: 5.4, got: $UE_VERSION"
  exit 1
fi
echo ""

echo "Test 3: Requirements from file (simulating requirements_file input)"
echo "--------------------------------------------------------------------"
cat > requirements_input.md << 'EOF'
# Network Protocol Plugin
Create a plugin called NetProtocol for UE 5.3
With "advanced" networking features
EOF

REQ=$(cat requirements_input.md)
printf '%s' "$REQ" > requirements.txt
echo "✓ Requirements written to requirements.txt"

export REQUIREMENTS_FILE=requirements.txt
export PLUGIN_NAME=""
export UE_VERSION=""
python3 parser.py > spec.json
PLUGIN_NAME=$(jq -r .plugin_name spec.json)
UE_VERSION=$(jq -r .ue_version spec.json)
echo "✓ Resolved plugin name: $PLUGIN_NAME"
echo "✓ Resolved UE version: $UE_VERSION"

if [ "$PLUGIN_NAME" != "NetProtocol" ]; then
  echo "✗ Expected plugin name: NetProtocol, got: $PLUGIN_NAME"
  exit 1
fi
if [ "$UE_VERSION" != "5.3" ]; then
  echo "✗ Expected UE version: 5.3, got: $UE_VERSION"
  exit 1
fi
echo ""

echo "Test 4: Create issue step with requirements from file"
echo "------------------------------------------------------"
PLUGIN="TestPlugin"
UE_VERSION="5.5"
REQUIREMENTS=$(cat requirements.txt)

# Verify we can safely read requirements and use them
if [ -z "$REQUIREMENTS" ]; then
  echo "✗ Failed to read requirements from file"
  exit 1
fi

echo "✓ Successfully read requirements from file for issue creation"
echo "  Length: ${#REQUIREMENTS} characters"
echo ""

echo "Test 5: Empty requirements"
echo "--------------------------"
REQ=""
printf '%s' "$REQ" > requirements.txt
echo "✓ Empty requirements written to requirements.txt"

export REQUIREMENTS_FILE=requirements.txt
export PLUGIN_NAME=""
export UE_VERSION=""
python3 parser.py > spec.json
PLUGIN_NAME=$(jq -r .plugin_name spec.json)
UE_VERSION=$(jq -r .ue_version spec.json)
echo "✓ Resolved plugin name: $PLUGIN_NAME (using fallback)"
echo "✓ Resolved UE version: $UE_VERSION (using default)"

if [ "$PLUGIN_NAME" != "NewPlugin" ]; then
  echo "✗ Expected fallback plugin name: NewPlugin, got: $PLUGIN_NAME"
  exit 1
fi
if [ "$UE_VERSION" != "5.6" ]; then
  echo "✗ Expected default UE version: 5.6, got: $UE_VERSION"
  exit 1
fi
echo ""

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo "=== All workflow simulation tests passed! ==="
