# ABOUTME: Tests that the Query workflow in wikify.md covers all required steps.
# ABOUTME: Verifies index lookup, synthesis, citations, gap detection, and save option.

FAILURES=0
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$PROJECT_DIR/src/wikify.md"

assert_contains "$SKILL" "index.md" "Query reads index.md"
assert_contains "$SKILL" "overview.md" "Query reads overview.md"
assert_contains "$SKILL" "relevant" "Query identifies relevant pages"
assert_contains "$SKILL" "synthesize\|Synthesize\|answer\|Answer" "Query synthesizes an answer"
assert_contains "$SKILL" "citation\|cite" "Query includes citations"
assert_contains "$SKILL" "gap" "Query detects knowledge gaps"
assert_contains "$SKILL" "suggest" "Query suggests sources to fill gaps"
assert_contains "$SKILL" "save\|Save" "Query offers to save answer as wiki page"
