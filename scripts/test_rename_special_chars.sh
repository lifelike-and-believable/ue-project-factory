#!/usr/bin/env bash
# Test script to validate rename logic with special characters in plugin names
set -euo pipefail

echo "Testing rename logic with special characters in plugin names"
echo "============================================================="

# Test 1: Plugin name with ampersand
echo -e "\nTest 1: Plugin name 'TestAnd' (no special chars - baseline)"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
mkdir -p "Plugins/SamplePlugin/Source/SamplePlugin"
echo '{"Modules": [{"Name": "SamplePlugin"}]}' > "Plugins/SamplePlugin/SamplePlugin.uplugin"
echo '#include "SamplePlugin.h"' > "Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.cpp"
echo 'IMPLEMENT_MODULE(FSamplePluginModule, SamplePlugin)' >> "Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.cpp"

git init
git config user.name "Test"
git config user.email "test@test.com"
git add -A
git commit -m "init"

PLUGIN_NAME="TestAnd"
PLUGIN_NAME_ESCAPED=$(printf '%s\n' "$PLUGIN_NAME" | sed 's/[&/\]/\\&/g')
git grep -lz "SamplePlugin" 2>/dev/null | xargs -0 -r sed -i "s/SamplePlugin/$PLUGIN_NAME_ESCAPED/g"

# Verify
if grep -q "TestAnd" "Plugins/SamplePlugin/SamplePlugin.uplugin" && \
   grep -q "#include \"TestAnd.h\"" "Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.cpp" && \
   grep -q "IMPLEMENT_MODULE(FTestAndModule, TestAnd)" "Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.cpp"; then
  echo "  ✓ Test 1 PASSED"
else
  echo "  ✗ Test 1 FAILED"
  cat "Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.cpp"
  exit 1
fi

cd /
rm -rf "$TEST_DIR"

# Test 2: Plugin name with special chars that would break without escaping
# Note: We can't actually test with & or \ in plugin names because they're invalid
# for UE plugin names, but we test that the escaping logic doesn't break normal names
echo -e "\nTest 2: Plugin name 'Test2' (typical case)"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
mkdir -p "Plugins/SamplePlugin/Source/SamplePlugin"
echo '{"Modules": [{"Name": "SamplePlugin"}]}' > "Plugins/SamplePlugin/SamplePlugin.uplugin"
echo '#include "SamplePlugin.h"' > "Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.cpp"
echo 'IMPLEMENT_MODULE(FSamplePluginModule, SamplePlugin)' >> "Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.cpp"

git init
git config user.name "Test"
git config user.email "test@test.com"
git add -A
git commit -m "init"

PLUGIN_NAME="Test2"
PLUGIN_NAME_ESCAPED=$(printf '%s\n' "$PLUGIN_NAME" | sed 's/[&/\]/\\&/g')
git grep -lz "SamplePlugin" 2>/dev/null | xargs -0 -r sed -i "s/SamplePlugin/$PLUGIN_NAME_ESCAPED/g"

# Verify
if grep -q "Test2" "Plugins/SamplePlugin/SamplePlugin.uplugin" && \
   grep -q "#include \"Test2.h\"" "Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.cpp" && \
   grep -q "IMPLEMENT_MODULE(FTest2Module, Test2)" "Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.cpp"; then
  echo "  ✓ Test 2 PASSED"
else
  echo "  ✗ Test 2 FAILED"
  cat "Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.cpp"
  exit 1
fi

cd /
rm -rf "$TEST_DIR"

# Test 3: Plugin name with number at start (edge case, but should work)
echo -e "\nTest 3: Plugin name 'TestNumber123'"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
mkdir -p "Plugins/SamplePlugin/Source/SamplePlugin"
echo '{"Modules": [{"Name": "SamplePlugin"}]}' > "Plugins/SamplePlugin/SamplePlugin.uplugin"
echo '#include "SamplePlugin.h"' > "Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.cpp"

git init
git config user.name "Test"
git config user.email "test@test.com"
git add -A
git commit -m "init"

PLUGIN_NAME="TestNumber123"
PLUGIN_NAME_ESCAPED=$(printf '%s\n' "$PLUGIN_NAME" | sed 's/[&/\]/\\&/g')
git grep -lz "SamplePlugin" 2>/dev/null | xargs -0 -r sed -i "s/SamplePlugin/$PLUGIN_NAME_ESCAPED/g"

# Verify
if grep -q "TestNumber123" "Plugins/SamplePlugin/SamplePlugin.uplugin" && \
   grep -q "#include \"TestNumber123.h\"" "Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.cpp"; then
  echo "  ✓ Test 3 PASSED"
else
  echo "  ✗ Test 3 FAILED"
  cat "Plugins/SamplePlugin/Source/SamplePlugin/SamplePlugin.cpp"
  exit 1
fi

cd /
rm -rf "$TEST_DIR"

# Test 4: Escaping function itself
echo -e "\nTest 4: Verify escaping function works correctly"
test_escape() {
  local input="$1"
  local expected="$2"
  local result=$(printf '%s\n' "$input" | sed 's/[&/\]/\\&/g')
  if [ "$result" = "$expected" ]; then
    echo "  ✓ '$input' -> '$expected' PASSED"
  else
    echo "  ✗ '$input' -> expected '$expected', got '$result' FAILED"
    exit 1
  fi
}

test_escape "Normal" "Normal"
test_escape "Test2" "Test2"
test_escape "Test&Name" "Test\\&Name"
test_escape "Test/Name" "Test\\/Name"
test_escape "Test\\Name" "Test\\\\Name"

echo -e "\n✓ All special character tests passed!"
