# ABOUTME: Tests that the Ingest workflow in wikify.md covers all required steps.
# ABOUTME: Verifies file discovery, reading, summary, page creation, and cross-referencing.

FAILURES=0
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$PROJECT_DIR/src/wikify.md"

# File discovery
assert_contains "$SKILL" "raw/\*\*" "Ingest scans raw/ recursively"
assert_contains "$SKILL" "log.md" "Ingest checks log.md for processed files"
assert_contains "$SKILL" "unprocessed" "Ingest identifies unprocessed files"
assert_contains "$SKILL" "one file\|one at a time\|one-at-a-time" "Ingest processes one file at a time"
assert_contains "$SKILL" "DS_Store\|\.DS_Store" "Ingest excludes .DS_Store"

# File reading by type
assert_contains "$SKILL" "\.pdf\|PDF" "Ingest handles PDF files"
assert_contains "$SKILL" "\.png\|\.jpg\|images\|vision" "Ingest handles image files"
assert_contains "$SKILL" "Read tool" "Ingest uses Read tool for text files"

# Summary and discussion
assert_contains "$SKILL" "bullet" "Ingest presents bullet summary"
assert_contains "$SKILL" "entities\|Entities" "Ingest identifies entities"
assert_contains "$SKILL" "concepts\|Concepts" "Ingest identifies concepts"
assert_contains "$SKILL" "contradiction" "Ingest flags contradictions"
assert_contains "$SKILL" "context\|direction" "Ingest asks for user context"

# Page creation
assert_contains "$SKILL" "wiki/sources/" "Ingest creates source summary pages"
assert_contains "$SKILL" "wiki/concepts/" "Ingest creates/updates concept pages"
assert_contains "$SKILL" "wiki/entities/" "Ingest creates/updates entity pages"
assert_contains "$SKILL" "wiki/comparisons/" "Ingest creates comparison pages"
assert_contains "$SKILL" "type:" "Ingest uses type frontmatter field"
assert_contains "$SKILL" "updated:" "Ingest tracks updated date"

# Cross-references
assert_contains "$SKILL" "bidirectional\|cross-reference\|Cross-Reference" "Ingest maintains bidirectional links"
