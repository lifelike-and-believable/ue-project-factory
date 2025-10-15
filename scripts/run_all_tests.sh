#!/usr/bin/env bash
# Test runner - runs all test suites for the project factory
set -euo pipefail

cd "$(dirname "$0")/.."

echo "================================================"
echo "  Project Factory - Test Suite Runner"
echo "================================================"
echo ""

# Track overall results
TOTAL_PASSED=0
TOTAL_FAILED=0

# Test 1: Parser unit tests
echo "1. Parser Unit Tests"
echo "--------------------"
if python3 scripts/test_parser.py; then
  TOTAL_PASSED=$((TOTAL_PASSED + 1))
  echo ""
else
  TOTAL_FAILED=$((TOTAL_FAILED + 1))
  echo "✗ Parser tests failed"
  echo ""
fi

# Test 2: Requirements File Handling Tests
echo "2. Requirements File Handling Tests"
echo "------------------------------------"
if python3 scripts/test_requirements_file.py; then
  TOTAL_PASSED=$((TOTAL_PASSED + 1))
  echo ""
else
  TOTAL_FAILED=$((TOTAL_FAILED + 1))
  echo "✗ Requirements file tests failed"
  echo ""
fi

# Test 3: Rename logic tests
echo "3. Rename Logic Tests"
echo "---------------------"
if bash scripts/test_rename.sh 2>&1 | grep -v "^hint:" | grep -v "^Initialized" | grep -v "^\[master"; then
  TOTAL_PASSED=$((TOTAL_PASSED + 1))
  echo ""
else
  TOTAL_FAILED=$((TOTAL_FAILED + 1))
  echo "✗ Rename tests failed"
  echo ""
fi

# Test 4: Workflow simulation tests
echo "4. Workflow Simulation Tests"
echo "-----------------------------"
if bash scripts/test_workflow_simulation.sh; then
  TOTAL_PASSED=$((TOTAL_PASSED + 1))
  echo ""
else
  TOTAL_FAILED=$((TOTAL_FAILED + 1))
  echo "✗ Workflow simulation tests failed"
  echo ""
fi

# Test 5: Integration tests
echo "5. Integration Tests"
echo "--------------------"
if bash scripts/test_integration.sh; then
  TOTAL_PASSED=$((TOTAL_PASSED + 1))
  echo ""
else
  TOTAL_FAILED=$((TOTAL_FAILED + 1))
  echo "✗ Integration tests failed"
  echo ""
fi

# Summary
echo "================================================"
echo "  Test Summary"
echo "================================================"
echo "Test Suites Passed: $TOTAL_PASSED/5"
echo "Test Suites Failed: $TOTAL_FAILED/5"
echo ""

if [ $TOTAL_FAILED -eq 0 ]; then
  echo "✓ All test suites passed!"
  exit 0
else
  echo "✗ Some test suites failed"
  exit 1
fi
