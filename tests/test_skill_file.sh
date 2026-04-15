# ABOUTME: Tests that src/wikify.md has correct structure and all workflow sections.
# ABOUTME: Verifies YAML frontmatter, auto-detection logic, and workflow headings.

FAILURES=0
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$PROJECT_DIR/src/wikify.md"

assert_file_exists "$SKILL" "skill file exists"
assert_first_line "$SKILL" "---" "skill file starts with YAML frontmatter"
assert_contains "$SKILL" "description:" "skill file has description frontmatter"
assert_contains "$SKILL" "Init" "skill file references Init workflow"
assert_contains "$SKILL" "Ingest" "skill file references Ingest workflow"
assert_contains "$SKILL" "Query" "skill file references Query workflow"
assert_contains "$SKILL" "Lint" "skill file references Lint workflow"
assert_contains "$SKILL" "raw/" "skill file references raw/ directory"
assert_contains "$SKILL" "wiki/" "skill file references wiki/ directory"
assert_contains "$SKILL" "WIKI_SCHEMA.md" "skill file references WIKI_SCHEMA.md"
assert_contains "$SKILL" "auto-detect\|Auto-Detect\|detect.*context\|Detect.*Context" "skill file has auto-detection logic"
