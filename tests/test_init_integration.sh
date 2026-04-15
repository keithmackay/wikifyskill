# ABOUTME: Integration tests verifying schema content consistency.
# ABOUTME: Ensures the template and the skill file stay in sync on key terms.

FAILURES=0
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA="$PROJECT_DIR/src/templates/WIKI_SCHEMA.md"
SKILL="$PROJECT_DIR/src/wikify.md"

assert_file_exists "$SCHEMA" "schema template exists"
assert_file_exists "$SKILL" "skill file exists"

# Both files must contain these key terms
for term in "source-summary" "confidence:" "kebab-case" "concept" "entity" "comparison" "read-only"; do
  assert_contains "$SCHEMA" "$term" "schema template contains '$term'"
  assert_contains "$SKILL" "$term" "skill file contains '$term'"
done
