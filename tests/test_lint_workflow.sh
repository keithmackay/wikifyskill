# ABOUTME: Tests that the Lint workflow in wikify.md covers all six health checks.
# ABOUTME: Verifies contradiction, orphan, stale, cross-ref, stub, and broken link checks.

FAILURES=0
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$PROJECT_DIR/src/wikify.md"

assert_contains "$SKILL" "Contradiction" "Lint checks for contradictions"
assert_contains "$SKILL" "Orphan\|orphan" "Lint checks for orphan pages"
assert_contains "$SKILL" "Stale\|stale" "Lint checks for stale claims"
assert_contains "$SKILL" "cross-reference\|Cross-Reference\|backlink" "Lint checks for missing cross-references"
assert_contains "$SKILL" "Stub\|stub" "Lint checks for stub detection"
assert_contains "$SKILL" "Broken\|broken" "Lint checks for broken links"
assert_contains "$SKILL" "summary\|Summary\|table" "Lint presents results summary"
assert_contains "$SKILL" "one at a time\|approval\|approve" "Lint fixes one at a time with approval"
