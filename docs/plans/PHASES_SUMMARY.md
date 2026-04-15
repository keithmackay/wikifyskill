# wikifyskill — Phases Summary

Quick reference guide to the implementation roadmap. See `IMPLEMENTATION_PLAN.md` for full detail.

## Technology Stack

- **Deliverable**: Single markdown file (`wikify.md`) — Claude Code global slash command
- **Testing**: Shell scripts with grep-based assertions (`tests/test_*.sh`)
- **Install**: Shell scripts (`scripts/install.sh`, `scripts/uninstall.sh`)
- **Runtime Dependencies**: None — Claude Code interprets the markdown at runtime
- **Output Format**: Obsidian-compatible markdown with YAML frontmatter

## Key Principles

- **TDD**: Write failing test → implement → verify pass (adapted for markdown: grep assertions)
- **YAGNI**: No speculative features, no unnecessary abstractions
- **DRY**: Schema template is source of truth; inlined into skill file for runtime
- **Frequent commits**: `Phase X.Y: Description` format
- **ABOUTME comments**: Required on all shell scripts

---

## Phase 0: Project Scaffolding 🔲 Not Started

**Goal**: Set up repo structure, testing framework, and install/uninstall scripts.

| Task | Description |
|------|-------------|
| 0.1 | Create directory structure (`src/`, `src/templates/`, `tests/`, `scripts/`) |
| 0.2 | Create test runner (`tests/run_tests.sh`) and shared helpers (`tests/helpers.sh`) |
| 0.3 | Create install/uninstall scripts with tests |

**Deliverables**: Working test runner, install.sh, uninstall.sh, test_install.sh

---

## Phase 1: WIKI_SCHEMA.md Template 🔲 Not Started

**Goal**: Create the schema template generated during Init.

| Task | Description |
|------|-------------|
| 1.1 | Write `src/templates/WIKI_SCHEMA.md` with tests verifying all required sections |

**Deliverables**: Complete WIKI_SCHEMA.md template, test_schema_template.sh

---

## Phase 2: Skill File — Init Workflow 🔲 Not Started

**Goal**: Create the main skill file with auto-detection and Init workflow.

| Task | Description |
|------|-------------|
| 2.1 | Create `src/wikify.md` skeleton with YAML frontmatter and auto-detection logic |
| 2.2 | Write the full Init workflow (folder creation, schema, index, log, overview) |
| 2.3 | Integration test verifying schema content consistency between template and skill file |

**Deliverables**: src/wikify.md with working Init, test_skill_file.sh, test_init_workflow.sh, test_init_integration.sh

---

## Phase 3: Ingest Workflow 🔲 Not Started

**Goal**: Add the Ingest workflow — the core operation.

| Task | Description |
|------|-------------|
| 3.1 | File discovery section (scan raw/, compare against log.md, identify new files) |
| 3.2 | Single-file processing (read, summarize, discuss, create/update pages, cross-reference) |

**Deliverables**: Complete Ingest workflow in wikify.md, test_ingest_workflow.sh

---

## Phase 4: Query Workflow 🔲 Not Started

**Goal**: Add the Query workflow for answering questions from compiled wiki.

| Task | Description |
|------|-------------|
| 4.1 | Full query workflow (index lookup, page reading, synthesis, citations, gap detection, save option) |

**Deliverables**: Complete Query workflow in wikify.md, test_query_workflow.sh

---

## Phase 5: Lint Workflow 🔲 Not Started

**Goal**: Add the Lint workflow for wiki health checks.

| Task | Description |
|------|-------------|
| 5.1 | All six checks: contradictions, orphans, stale claims, missing cross-refs, stubs, broken links |

**Deliverables**: Complete Lint workflow in wikify.md, test_lint_workflow.sh

---

## Phase 6: Polish and Documentation 🔲 Not Started

**Goal**: Edge cases, docs, license, final verification.

| Task | Description |
|------|-------------|
| 6.1 | Add edge case handling (inconsistent state, empty raw/, menu mode) |
| 6.2 | Update README.md with full documentation |
| 6.3 | Add MIT LICENSE |
| 6.4 | Update docs/TESTING_GUIDELINES.md for this project |
| 6.5 | Final test pass and verified install |

**Deliverables**: Production-ready README, LICENSE, updated TESTING_GUIDELINES.md, clean test pass, installed skill

---

## Success Criteria

1. `./tests/run_tests.sh` passes all tests (zero failures)
2. `./scripts/install.sh` installs `wikify.md` to `~/.claude/commands/`
3. `/wikify` in a fresh directory creates correct 3-layer folder structure
4. `/wikify` with files in `raw/` triggers one-at-a-time ingest with discussion
5. `/wikify <question>` synthesizes answers from wiki with citations
6. `/wikify lint` runs all six health checks and offers fixes
7. All wiki pages are Obsidian-compatible markdown with correct YAML frontmatter

## Post-Launch Maintenance

- **Schema evolution**: Update `src/templates/WIKI_SCHEMA.md` first, then sync into `src/wikify.md`. Integration tests catch drift.
- **New file types**: Add reading instructions to the Ingest Step 2 section of `src/wikify.md`.
- **New lint checks**: Add to the Lint section and update `tests/test_lint_workflow.sh`.
- **Reinstall after changes**: Run `./scripts/install.sh` to update the global command.
