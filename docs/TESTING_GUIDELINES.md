# Testing Guidelines — wikifyskill

## Overview

wikifyskill's deliverable is a markdown skill file, not application code. Tests are shell scripts that use grep-based assertions to verify the skill file contains the correct instructions.

This is TDD adapted for prompt engineering: write assertions about what the skill file must contain, then write the skill content to satisfy them.

## Running Tests

Run all tests:

```bash
./tests/run_tests.sh
```

Run a single test file:

```bash
./tests/run_tests.sh tests/test_skill_file.sh
```

## Test Structure

```
tests/
├── helpers.sh                 # Shared assertion functions
├── run_tests.sh               # Test runner (discovers test_*.sh files)
├── test_skill_file.sh         # Skill file structure and frontmatter
├── test_schema_template.sh    # WIKI_SCHEMA.md template content
├── test_init_workflow.sh      # Init workflow folder structure and templates
├── test_init_integration.sh   # Schema consistency between template and skill
├── test_ingest_workflow.sh    # Ingest workflow steps and content
├── test_query_workflow.sh     # Query workflow steps and content
├── test_lint_workflow.sh      # Lint workflow six health checks
├── test_edge_cases.sh         # Edge case handling
└── test_install.sh            # Install/uninstall script behavior
```

## Available Assertions

Defined in `tests/helpers.sh`:

- `assert_contains FILE PATTERN DESCRIPTION` — Grep for pattern in file
- `assert_not_contains FILE PATTERN DESCRIPTION` — Verify pattern is absent
- `assert_file_exists FILE DESCRIPTION` — Check file exists
- `assert_file_not_exists FILE DESCRIPTION` — Check file is absent
- `assert_first_line FILE EXPECTED DESCRIPTION` — Check first line of file

## Adding a New Test

1. Create `tests/test_yourname.sh`
2. Start with `FAILURES=0` and reference `PROJECT_DIR`
3. Call assertion functions (they're sourced by `run_tests.sh`)
4. The runner picks it up automatically (no registration needed)

Example:

```bash
# ABOUTME: Tests for a new feature.
# ABOUTME: Verifies the skill file contains new feature instructions.

FAILURES=0
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$PROJECT_DIR/src/wikify.md"

assert_contains "$SKILL" "new feature keyword" "skill mentions new feature"
```

## What Tests Can and Cannot Verify

**Can verify**: File existence, YAML frontmatter structure, presence of required instructions, template completeness, install/uninstall behavior, content consistency between files.

**Cannot verify**: Whether Claude correctly interprets the instructions at runtime. That requires manual QA — run `/wikify` in a test project and exercise each workflow.
