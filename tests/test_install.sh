# ABOUTME: Tests for install.sh and uninstall.sh scripts.
# ABOUTME: Verifies install copies wikify.md and uninstall removes it.

FAILURES=0
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Create a dummy src/wikify.md for now (will be replaced by real file later)
if [ ! -f "$PROJECT_DIR/src/wikify.md" ]; then
  mkdir -p "$PROJECT_DIR/src"
  echo "---" > "$PROJECT_DIR/src/wikify.md"
  echo "description: test placeholder" >> "$PROJECT_DIR/src/wikify.md"
  echo "---" >> "$PROJECT_DIR/src/wikify.md"
  CREATED_DUMMY=1
fi

# Set up temp install dir
TMPDIR_INSTALL=$(mktemp -d)
export WIKIFY_INSTALL_DIR="$TMPDIR_INSTALL"

# Test install
"$PROJECT_DIR/scripts/install.sh"
assert_file_exists "$TMPDIR_INSTALL/wikify.md" "install.sh copies wikify.md to install dir"

# Test that installed file has frontmatter
assert_first_line "$TMPDIR_INSTALL/wikify.md" "---" "installed file starts with YAML frontmatter"

# Test uninstall
"$PROJECT_DIR/scripts/uninstall.sh"
assert_file_not_exists "$TMPDIR_INSTALL/wikify.md" "uninstall.sh removes wikify.md"

# Test uninstall is idempotent (doesn't error on missing file)
"$PROJECT_DIR/scripts/uninstall.sh"
assert_file_not_exists "$TMPDIR_INSTALL/wikify.md" "uninstall.sh handles already-removed file"

# Clean up
rm -rf "$TMPDIR_INSTALL"
if [ "${CREATED_DUMMY:-0}" = "1" ]; then
  rm -f "$PROJECT_DIR/src/wikify.md"
fi
