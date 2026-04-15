# ABOUTME: Tests that src/templates/WIKI_SCHEMA.md contains all required sections.
# ABOUTME: Verifies page types, frontmatter fields, naming conventions, and special files.

FAILURES=0
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA="$PROJECT_DIR/src/templates/WIKI_SCHEMA.md"

assert_file_exists "$SCHEMA" "WIKI_SCHEMA.md template exists"
assert_contains "$SCHEMA" "source-summary" "schema defines source-summary page type"
assert_contains "$SCHEMA" "concept" "schema defines concept page type"
assert_contains "$SCHEMA" "entity" "schema defines entity page type"
assert_contains "$SCHEMA" "comparison" "schema defines comparison page type"
assert_contains "$SCHEMA" "confidence:" "schema includes confidence frontmatter field"
assert_contains "$SCHEMA" "raw/" "schema references raw/ directory"
assert_contains "$SCHEMA" "wiki/" "schema references wiki/ directory"
assert_contains "$SCHEMA" "kebab-case" "schema specifies kebab-case naming"
assert_contains "$SCHEMA" "index.md" "schema documents index.md"
assert_contains "$SCHEMA" "log.md" "schema documents log.md"
assert_contains "$SCHEMA" "overview.md" "schema documents overview.md"
assert_contains "$SCHEMA" "title:" "schema includes title frontmatter field"
assert_contains "$SCHEMA" "type:" "schema includes type frontmatter field"
assert_contains "$SCHEMA" "sources:" "schema includes sources frontmatter field"
assert_contains "$SCHEMA" "related:" "schema includes related frontmatter field"
assert_contains "$SCHEMA" "created:" "schema includes created frontmatter field"
assert_contains "$SCHEMA" "updated:" "schema includes updated frontmatter field"
assert_contains "$SCHEMA" "read-only" "schema marks raw/ as read-only"
assert_contains "$SCHEMA" "Ingest" "schema documents Ingest workflow"
assert_contains "$SCHEMA" "Query" "schema documents Query workflow"
assert_contains "$SCHEMA" "Lint" "schema documents Lint workflow"
