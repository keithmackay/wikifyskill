# ABOUTME: Tests for install.sh and uninstall.sh scripts.
# ABOUTME: Verifies install copies the command and skill, and uninstall removes both.

FAILURES=0
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Set up isolated temp install dirs
TMPDIR_COMMANDS=$(mktemp -d)
TMPDIR_SKILLS=$(mktemp -d)
export WIKIFY_COMMANDS_DIR="$TMPDIR_COMMANDS"
export WIKIFY_SKILLS_DIR="$TMPDIR_SKILLS/wikify"

# Test install
"$PROJECT_DIR/scripts/install.sh"
assert_file_exists "$TMPDIR_COMMANDS/wikify.md" "install.sh copies wikify.md to WIKIFY_COMMANDS_DIR"
assert_file_exists "$WIKIFY_SKILLS_DIR/SKILL.md" "install.sh copies the skill to WIKIFY_SKILLS_DIR"
assert_file_exists "$WIKIFY_SKILLS_DIR/scripts/build-site.sh" "install.sh copies build-site.sh into the skill's scripts/ dir"

# Test that installed file has frontmatter
assert_first_line "$TMPDIR_COMMANDS/wikify.md" "---" "installed command file starts with YAML frontmatter"

# Test uninstall
"$PROJECT_DIR/scripts/uninstall.sh"
assert_file_not_exists "$TMPDIR_COMMANDS/wikify.md" "uninstall.sh removes wikify.md"
assert_file_not_exists "$WIKIFY_SKILLS_DIR/SKILL.md" "uninstall.sh removes the skill directory"

# Test uninstall is idempotent (doesn't error on missing file)
"$PROJECT_DIR/scripts/uninstall.sh"
assert_file_not_exists "$TMPDIR_COMMANDS/wikify.md" "uninstall.sh handles already-removed file"

# Clean up
rm -rf "$TMPDIR_COMMANDS" "$TMPDIR_SKILLS"
