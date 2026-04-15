# ABOUTME: Tests that the skill file handles edge cases properly.
# ABOUTME: Verifies inconsistent state, empty raw/, and menu mode.

FAILURES=0
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$PROJECT_DIR/src/wikify.md"

assert_contains "$SKILL" "Inconsistent\|inconsistent\|incomplete" "handles inconsistent state (raw without wiki or vice versa)"
assert_contains "$SKILL" "no.*file\|empty\|No source\|Nothing to do\|nothing to do" "handles no files to process"
assert_contains "$SKILL" "menu\|What would you like\|options" "presents menu when nothing to do"
