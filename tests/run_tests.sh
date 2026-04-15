#!/usr/bin/env bash
# ABOUTME: Test runner for wikifyskill. Discovers and runs all tests/test_*.sh files.
# ABOUTME: Accepts an optional argument to run a single test file.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

total_pass=0
total_fail=0
files_run=0

run_test_file() {
  local test_file="$1"
  local name
  name=$(basename "$test_file")
  echo ""
  echo "--- $name ---"

  FAILURES=0
  PASSES=0
  export FAILURES PASSES

  # Source helpers and the test file in a subshell-like scope
  (
    source "$SCRIPT_DIR/helpers.sh"
    FAILURES=0
    PASSES=0
    source "$test_file"
    echo "  ($PASSES passed, $FAILURES failed)"
    exit "$FAILURES"
  )
  local exit_code=$?

  if [ "$exit_code" -gt 0 ]; then
    total_fail=$((total_fail + exit_code))
  fi
  files_run=$((files_run + 1))
}

if [ -n "$1" ]; then
  # Run a single test file
  if [ -f "$1" ]; then
    run_test_file "$1"
  elif [ -f "$SCRIPT_DIR/$1" ]; then
    run_test_file "$SCRIPT_DIR/$1"
  else
    echo "Test file not found: $1"
    exit 1
  fi
else
  # Run all test files
  test_files=("$SCRIPT_DIR"/test_*.sh)
  if [ "${test_files[0]}" = "$SCRIPT_DIR/test_*.sh" ]; then
    echo "No test files found."
    echo ""
    echo "0 test files run, 0 failures"
    exit 0
  fi
  for test_file in "${test_files[@]}"; do
    run_test_file "$test_file"
  done
fi

echo ""
echo "================================"
echo "$files_run test file(s) run, $total_fail failure(s)"
echo "================================"

if [ "$total_fail" -gt 0 ]; then
  exit 1
fi
