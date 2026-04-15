# ABOUTME: Tests that the Init workflow section in wikify.md contains all required content.
# ABOUTME: Verifies folder structure, schema inline content, and initial file templates.

FAILURES=0
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$PROJECT_DIR/src/wikify.md"

# Folder structure
assert_contains "$SKILL" "raw/articles" "Init creates raw/articles"
assert_contains "$SKILL" "raw/papers" "Init creates raw/papers"
assert_contains "$SKILL" "raw/repos" "Init creates raw/repos"
assert_contains "$SKILL" "raw/data" "Init creates raw/data"
assert_contains "$SKILL" "raw/images" "Init creates raw/images"
assert_contains "$SKILL" "raw/assets" "Init creates raw/assets"
assert_contains "$SKILL" "wiki/concepts" "Init creates wiki/concepts"
assert_contains "$SKILL" "wiki/entities" "Init creates wiki/entities"
assert_contains "$SKILL" "wiki/sources" "Init creates wiki/sources"
assert_contains "$SKILL" "wiki/comparisons" "Init creates wiki/comparisons"

# Schema and special files
assert_contains "$SKILL" "WIKI_SCHEMA.md" "Init creates WIKI_SCHEMA.md"
assert_contains "$SKILL" "wiki/index.md" "Init creates wiki/index.md"
assert_contains "$SKILL" "wiki/log.md" "Init creates wiki/log.md"
assert_contains "$SKILL" "wiki/overview.md" "Init creates wiki/overview.md"

# Initial content
assert_contains "$SKILL" "Wiki Index" "Init seeds index.md with title"
assert_contains "$SKILL" "Processing Log" "Init seeds log.md with title"
assert_contains "$SKILL" "Wiki Overview" "Init seeds overview.md with title"
