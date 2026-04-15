# ABOUTME: Shared test helper functions for wikifyskill shell-based tests.
# ABOUTME: Provides assert_contains, assert_file_exists, assert_file_not_exists.

PASSES=0

assert_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if grep -q -- "$pattern" "$file" 2>/dev/null; then
    echo "  PASS: $description"
    PASSES=$((PASSES + 1))
  else
    echo "  FAIL: $description"
    echo "        Expected '$pattern' in $file"
    FAILURES=$((FAILURES + 1))
  fi
}

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if grep -q -- "$pattern" "$file" 2>/dev/null; then
    echo "  FAIL: $description"
    echo "        Did not expect '$pattern' in $file"
    FAILURES=$((FAILURES + 1))
  else
    echo "  PASS: $description"
    PASSES=$((PASSES + 1))
  fi
}

assert_file_exists() {
  local file="$1"
  local description="$2"
  if [ -f "$file" ]; then
    echo "  PASS: $description"
    PASSES=$((PASSES + 1))
  else
    echo "  FAIL: $description"
    echo "        File not found: $file"
    FAILURES=$((FAILURES + 1))
  fi
}

assert_file_not_exists() {
  local file="$1"
  local description="$2"
  if [ ! -f "$file" ]; then
    echo "  PASS: $description"
    PASSES=$((PASSES + 1))
  else
    echo "  FAIL: $description"
    echo "        File should not exist: $file"
    FAILURES=$((FAILURES + 1))
  fi
}

assert_first_line() {
  local file="$1"
  local expected="$2"
  local description="$3"
  local actual
  actual=$(head -n 1 "$file" 2>/dev/null)
  if [ "$actual" = "$expected" ]; then
    echo "  PASS: $description"
    PASSES=$((PASSES + 1))
  else
    echo "  FAIL: $description"
    echo "        Expected first line '$expected', got '$actual'"
    FAILURES=$((FAILURES + 1))
  fi
}
