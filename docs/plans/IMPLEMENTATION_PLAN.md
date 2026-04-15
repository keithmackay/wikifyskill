# wikifyskill — Detailed Implementation Plan

## What This Is

A single markdown file (`~/.claude/commands/wikify.md`) that serves as a Claude Code global slash command implementing Andrej Karpathy's LLM Wiki pattern. When a user types `/wikify` in any project directory, the skill auto-detects context (folder state) and runs one of four workflows: Init, Ingest, Query, or Lint.

**Architecture**: No application code. No npm packages. No server. The deliverable is a markdown skill file with natural-language instructions that Claude Code interprets and executes. Testing uses shell scripts that verify the skill file contains correct instructions.

**Repository**: `/Users/Keith.MacKay/Projects/wikifyskill`

## Key Reference Files

- `CLAUDE.md` — Project rules (TDD mandatory, YAGNI, ABOUTME comments, commit conventions with `Phase X.Y:` prefix, naming rules)
- `~/.claude/commands/start_session.md` — Example global slash command showing the required YAML frontmatter format (`---`, `description: ...`, `---`, then instructions)
- `README.md` — Project description (update in Phase 6)

## Claude Code Global Slash Command Format

Global commands live in `~/.claude/commands/` as `.md` files. Required format:

```
---
description: Short description shown in command list
---

[Natural language instructions for Claude to follow]
```

The `description` field in YAML frontmatter is required for global commands. The body is markdown instructions that Claude interprets at runtime.

---

## Phase 0: Project Scaffolding

**Goal**: Set up the repo structure, testing framework, and install/uninstall scripts.

### Task 0.1: Create directory structure

**Files to create**: The directories `src/`, `src/templates/`, `tests/`, `scripts/`.

**How to verify**: `ls -la src/ src/templates/ tests/ scripts/` shows all four directories.

**Commit**: `Phase 0.1: Create project directory structure`

### Task 0.2: Create the test runner and shared helpers

**Test first — but this IS the test infrastructure, so create it directly.**

**File to create**: `tests/helpers.sh`

This shared helper file must:
- Define `assert_contains()` that greps a file for a pattern, prints PASS or FAIL, and increments a `FAILURES` counter
- Define `assert_file_exists()` that checks file existence
- Define `assert_file_not_exists()` that checks file absence
- Include an ABOUTME comment at the top (per CLAUDE.md rules)

Every test file will `source` this helper. The FAILURES variable must be initialized to 0 by each test file before calling helpers.

**File to create**: `tests/run_tests.sh`

This shell script must:
- Use `set -e` at the top, but handle test failures via exit codes, not crashes
- Discover and run all `tests/test_*.sh` files
- Print each test file name before running it
- Track pass/fail counts
- Print a summary at the end
- Accept an optional argument to run a single test file
- Exit non-zero if any test failed
- Include ABOUTME comment

Mark both executable: `chmod +x tests/run_tests.sh tests/helpers.sh`

**How to verify**: `./tests/run_tests.sh` runs and reports "0 tests passed, 0 failed" (no test files yet).

**Commit**: `Phase 0.2: Create shell-based test runner and helpers`

### Task 0.3: Create install and uninstall scripts

**Test first**: Create `tests/test_install.sh`

This test must:
1. Source `tests/helpers.sh`
2. Create a temp directory to simulate `~/.claude/commands/`
3. Set env var `WIKIFY_INSTALL_DIR` to the temp dir
4. Run `scripts/install.sh`
5. Assert that `wikify.md` exists in the temp dir
6. Run `scripts/uninstall.sh`
7. Assert that `wikify.md` no longer exists
8. Clean up the temp dir

**File to create**: `scripts/install.sh`

Behavior: Read `WIKIFY_INSTALL_DIR` env var (default: `$HOME/.claude/commands`). Find `src/wikify.md` relative to the script location. Copy it to the install dir. Print confirmation. Exit 1 if source file not found.

**File to create**: `scripts/uninstall.sh`

Behavior: Read `WIKIFY_INSTALL_DIR` env var (default: `$HOME/.claude/commands`). Remove `wikify.md` from that dir. Print confirmation. Handle the case where the file is already gone.

Mark both executable. Include ABOUTME comments.

**How to verify**: `./tests/run_tests.sh` passes.

**Commit**: `Phase 0.3: Add install/uninstall scripts with tests`

---

## Phase 1: The WIKI_SCHEMA.md Template

**Goal**: Create the schema template that gets dropped into projects during Init.

### Task 1.1: Write the WIKI_SCHEMA.md template

**Test first**: Create `tests/test_schema_template.sh`

Assertions (all grep-based on `src/templates/WIKI_SCHEMA.md`):
1. File exists
2. Contains "source-summary"
3. Contains "concept"
4. Contains "entity"
5. Contains "comparison"
6. Contains "confidence:"
7. Contains "raw/"
8. Contains "wiki/"
9. Contains "kebab-case"
10. Contains "index.md"
11. Contains "log.md"

**File to create**: `src/templates/WIKI_SCHEMA.md`

This file documents the wiki structure for any human or LLM that encounters the project. It must define:

**Project Structure**: `raw/` is read-only source material with subdirectories (articles, papers, repos, data, images, assets). `wiki/` is LLM-owned output with subdirectories (concepts, entities, sources, comparisons).

**Page Types**:
- `source-summary` — one per source file, lives in `wiki/sources/`. Summarizes key takeaways, extracted entities/concepts, links back to the raw file.
- `concept` — one per significant idea/technique/pattern, lives in `wiki/concepts/`. Synthesizes information across multiple sources.
- `entity` — one per person, organization, tool, or project, lives in `wiki/entities/`. Aggregates all mentions and context.
- `comparison` — side-by-side analysis of alternatives, lives in `wiki/comparisons/`. Tables, trade-offs, recommendations.

**YAML Frontmatter Schema** (mandatory on every wiki page):
```yaml
---
title: Page Title
type: concept | entity | source-summary | comparison
sources:
  - ../raw/articles/source-file.md
related:
  - concepts/related-concept.md
  - entities/related-entity.md
confidence: high | medium | low
created: 2026-04-15
updated: 2026-04-15
---
```

**Naming Conventions**: Filenames are lowercase kebab-case slugs derived from the title (e.g., `transformer-architecture.md`). No spaces, no special characters beyond hyphens.

**Special Files**:
- `index.md` — categorical catalog. Format: `- [Title](path) — type: <type>, confidence: <level>` grouped by type (Sources, Concepts, Entities, Comparisons).
- `log.md` — append-only chronological record. Format: `## [YYYY-MM-DD] ingest | Source Title` followed by a brief note of what was created/updated.
- `overview.md` — high-level summary of the wiki's scope and key findings. Updated periodically.

**Workflow Summaries**: Brief human-readable descriptions of Init, Ingest, Query, and Lint workflows for reference.

**How to verify**: `./tests/run_tests.sh` passes.

**Commit**: `Phase 1.1: Create WIKI_SCHEMA.md template`

---

## Phase 2: The Skill File — Init Workflow

**Goal**: Create the main `src/wikify.md` skill file with auto-detection and the Init workflow.

### Task 2.1: Create the skill file skeleton with auto-detection logic

**Test first**: Create `tests/test_skill_file.sh`

Assertions:
1. `src/wikify.md` exists
2. First line is `---` (YAML frontmatter start)
3. Contains `description:` (frontmatter field)
4. Contains "Init" (workflow name)
5. Contains "Ingest" (workflow name)
6. Contains "Query" (workflow name)
7. Contains "Lint" (workflow name)
8. Contains "raw/" (detection target)
9. Contains "wiki/" (detection target)

**File to create**: `src/wikify.md`

Start with the YAML frontmatter:
```yaml
---
description: Build and maintain an LLM-compiled knowledge wiki (Karpathy pattern). Auto-detects context and runs Init, Ingest, Query, or Lint.
---
```

Then the main heading and auto-detection instructions:

**Step 1: Detect Context** — Examine the current working directory. The detection logic:
- **Init**: Neither `raw/` directory nor `wiki/` directory exists, or `WIKI_SCHEMA.md` does not exist
- **Ingest**: Both `raw/` and `wiki/` exist AND there are files in `raw/` not yet logged in `wiki/log.md`
- **Query**: Both `raw/` and `wiki/` exist AND all files are logged AND the user provided text after `/wikify` (that text is not "lint")
- **Lint**: The user included the word "lint" after `/wikify`
- **Menu**: Both dirs exist, all files logged, no question asked — offer options
- **Inconsistent state**: One of raw/wiki exists without the other — warn the user

Report the detected workflow and ask the user to confirm before proceeding.

Add placeholder sections (just headings) for each workflow — content comes in subsequent tasks.

**How to verify**: `./tests/run_tests.sh` passes.

**Commit**: `Phase 2.1: Create skill file skeleton with auto-detection logic`

### Task 2.2: Write the Init workflow section

**Test first**: Create `tests/test_init_workflow.sh`

Assertions on `src/wikify.md`:
1. Contains "raw/articles"
2. Contains "raw/papers"
3. Contains "raw/repos"
4. Contains "raw/data"
5. Contains "raw/images"
6. Contains "raw/assets"
7. Contains "wiki/concepts"
8. Contains "wiki/entities"
9. Contains "wiki/sources"
10. Contains "wiki/comparisons"
11. Contains "WIKI_SCHEMA.md"
12. Contains "wiki/index.md"
13. Contains "wiki/log.md"
14. Contains "wiki/overview.md"
15. Contains "Wiki Index" (index.md initial content)
16. Contains "Processing Log" (log.md initial content)

**Add to the skill file**: The full Init workflow section.

The Init section must instruct Claude to:
- Create all 10 subdirectories using `mkdir -p`:
  - `raw/articles`, `raw/papers`, `raw/repos`, `raw/data`, `raw/images`, `raw/assets`
  - `wiki/concepts`, `wiki/entities`, `wiki/sources`, `wiki/comparisons`
- Write `WIKI_SCHEMA.md` at the project root with the full schema content (inline the entire template from `src/templates/WIKI_SCHEMA.md` into the skill file — necessary because the skill runs in arbitrary directories and cannot reference repo files at runtime)
- Write `wiki/index.md` with header `# Wiki Index` and empty category sections (Sources, Concepts, Entities, Comparisons)
- Write `wiki/log.md` with header `# Processing Log` and an explanatory intro line
- Write `wiki/overview.md` with header `# Wiki Overview` and a placeholder description
- Print a closing message telling the user to add sources to `raw/` subdirectories and run `/wikify` again to begin ingesting

**Design note on schema duplication**: The WIKI_SCHEMA.md content lives in two places: `src/templates/WIKI_SCHEMA.md` (source of truth, used for testing) and inlined in `src/wikify.md` (the actual runtime skill file). The engineer must manually keep them in sync. Integration tests catch drift.

**How to verify**: `./tests/run_tests.sh` passes.

**Commit**: `Phase 2.2: Add Init workflow to skill file`

### Task 2.3: Integration test for schema content in installed file

**Test first**: Create `tests/test_init_integration.sh`

This test verifies the schema template and the skill file stay in sync:
1. Assert `src/templates/WIKI_SCHEMA.md` exists
2. Assert `src/wikify.md` exists
3. Assert both contain "source-summary"
4. Assert both contain "confidence:"
5. Assert both contain "kebab-case"
6. Assert both contain "concept"

Also update `tests/test_install.sh`: after install, assert the installed file contains "source-summary" (proving schema content is present in the installed copy). Use the real `src/wikify.md` instead of a dummy file.

**How to verify**: `./tests/run_tests.sh` passes.

**Commit**: `Phase 2.3: Add integration tests for schema content consistency`

---

## Phase 3: Ingest Workflow

**Goal**: Add the Ingest workflow to the skill file. This is the most complex workflow.

### Task 3.1: Write the Ingest workflow — file discovery section

**Test first**: Create `tests/test_ingest_workflow.sh`

Assertions:
1. Skill file contains instructions to scan `raw/` recursively
2. Contains instructions to read `wiki/log.md`
3. Contains "unprocessed" or "new file" (concept of new files)
4. Contains "one at a time" or "one file" (sequential processing)
5. Contains ".DS_Store" (system file exclusion)

**Add to the skill file**: Ingest Step 1 (Discover Unprocessed Files).

Instructions must tell Claude to:
- Use the Glob tool to scan `raw/` recursively for all files (pattern: `raw/**/*`)
- Exclude system files: `.DS_Store`, `.gitkeep`, `Thumbs.db`
- Read `wiki/log.md` and extract all source paths from log entries (look for paths after `ingest |` entries)
- Compare the two lists: any file in `raw/` whose path doesn't appear in `wiki/log.md` is unprocessed
- Report the count of new files and list them
- Ask the user which file to process first (or process in the order listed)

**How to verify**: `./tests/run_tests.sh` passes.

**Commit**: `Phase 3.1: Add Ingest workflow file discovery to skill file`

### Task 3.2: Write the Ingest workflow — single file processing

**Test first**: Add more assertions to `tests/test_ingest_workflow.sh`:

6. Contains instructions for reading by file type (grep for ".pdf" or "PDF")
7. Contains "bullet" (summary requirement)
8. Contains "entities" (entity identification)
9. Contains "concepts" (concept identification)
10. Contains "contradiction" (contradiction detection)
11. Contains instructions to ask for user context (grep for "context" or "direction")
12. Contains "wiki/sources/" (source summary creation)
13. Contains "wiki/concepts/" (concept page creation)
14. Contains "wiki/entities/" (entity page creation)
15. Contains "wiki/comparisons/" (comparison page creation)
16. Contains the frontmatter field "type:" (page type in schema)
17. Contains "bidirectional" or "cross-reference" (link maintenance)
18. Contains "updated:" (date tracking in frontmatter)

**Add to the skill file**: Ingest Steps 2-6.

**Step 2: Read the Source** — File-type-specific reading instructions:
- `.md`, `.txt`, `.csv`, `.json`, `.yaml`, `.yml`, and code files (`.py`, `.js`, `.ts`, `.rs`, `.go`, `.java`, `.c`, `.cpp`, `.h`, `.rb`, `.sh`): Use the Read tool directly
- `.pdf`: Use the `read_pdf_content` MCP tool
- Images (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg`): Use the Read tool (Claude sees images via vision)
- Directories in `raw/repos/`: Read README.md first, then key source files (entry points, config files)
- Fallback for unrecognized types: Report the file type and ask the user for a text summary or to convert it

**Step 3: Present Summary and Discuss** — Show the user:
- 3-5 bullet summary of key information extracted
- List of identified entities (people, organizations, tools, projects)
- List of identified concepts (techniques, patterns, theories, ideas)
- Any contradictions with existing wiki content (read relevant existing pages to check)
- Suggested wiki pages to create or update
- Then ask: "Any additional context or direction for how to file this?"

Wait for user input before proceeding. The user might correct misunderstandings, add context, or say "looks good."

**Step 4: Create/Update Wiki Pages** — For each page:
- **Source summary**: Always create in `wiki/sources/<slug>.md`. Use the full YAML frontmatter schema. The body should include: a summary paragraph, key takeaways as bullet points, notable quotes or data points, and links to related pages.
- **Concept pages**: Check `wiki/concepts/` for an existing page. If found, read it and append new information from this source. Add the source to the `sources:` frontmatter list. Update the `updated:` date. If not found, create a new page.
- **Entity pages**: Same create-or-update pattern in `wiki/entities/`.
- **Comparison pages**: Only create when the source explicitly compares alternatives, tools, or approaches. Use tables for side-by-side analysis.

All pages must use lowercase kebab-case filenames and the full frontmatter schema.

**Step 5: Update Index and Log**:
- Read `wiki/index.md`, add entries for all new pages under the appropriate category sections (Sources, Concepts, Entities, Comparisons). Format: `- [Title](relative-path) — type: <type>, confidence: <level>`
- Append to `wiki/log.md`: `## [YYYY-MM-DD] ingest | <Source Title>` followed by a bullet list of pages created/updated

**Step 6: Cross-Reference Pass**:
- Read all pages that were created or modified in this ingest
- For each page, check the `related:` frontmatter list
- Ensure bidirectional links: if page A lists page B in `related:`, then page B must also list page A
- Fix any missing backlinks

**Step 7: Offer to Continue**:
- If there are more unprocessed files, ask: "Process the next file, or stop here?"
- If no more files, report: "All sources processed. Run `/wikify` with a question to query the wiki, or `/wikify lint` for a health check."

**How to verify**: `./tests/run_tests.sh` passes.

**Commit**: `Phase 3.2: Add Ingest workflow file processing to skill file`

---

## Phase 4: Query Workflow

**Goal**: Add the Query workflow to the skill file.

### Task 4.1: Write the Query workflow

**Test first**: Create `tests/test_query_workflow.sh`

Assertions:
1. Contains "index.md" (index lookup)
2. Contains "relevant" (page relevance)
3. Contains "synthesize" or "answer" (answer construction)
4. Contains "citation" or "cite" (citation requirement)
5. Contains "gap" (knowledge gap detection)
6. Contains "suggest" (source suggestions)
7. Contains "save" (offer to save answer)
8. Contains "overview.md" (context reference)

**Add to the skill file**: The Query workflow section.

Instructions for Claude:
1. Parse the user's question from the text after `/wikify` (everything after the command)
2. Read `wiki/overview.md` for high-level context about the wiki's scope
3. Read `wiki/index.md` for the full page catalog
4. Identify relevant pages by matching the question against page titles, types, and one-line descriptions in the index
5. Read the identified relevant pages (typically 3-10 pages depending on the question)
6. Synthesize a comprehensive answer grounded in wiki content
7. Use inline citations in the format `(see [Page Title](wiki/path/page.md))` — link to wiki pages, not raw sources
8. Note confidence levels from source pages — if key claims come from low-confidence pages, say so
9. Identify knowledge gaps: topics the question touches that aren't well-covered in the wiki
10. Suggest specific source types that would fill the gaps (e.g., "a paper on X" or "documentation for Y")
11. At the end, ask: "Should I save this answer as a wiki page?" If yes, ask which type fits best (concept, comparison, or entity) and create the page with full frontmatter, updating index.md and log.md

**How to verify**: `./tests/run_tests.sh` passes.

**Commit**: `Phase 4.1: Add Query workflow to skill file`

---

## Phase 5: Lint Workflow

**Goal**: Add the Lint workflow to the skill file.

### Task 5.1: Write the Lint workflow

**Test first**: Create `tests/test_lint_workflow.sh`

Assertions:
1. Contains "contradiction" (check type)
2. Contains "orphan" (check type)
3. Contains "stale" (check type)
4. Contains "cross-reference" or "cross-ref" (check type)
5. Contains "stub" (check type)
6. Contains "broken" (broken link check)
7. Contains "summary" or "report" (results presentation)
8. Contains "one at a time" or "approval" (fix approach)

**Add to the skill file**: The Lint workflow section.

Six checks to run in order:

1. **Contradictions**: Read all wiki pages in concepts/, entities/, and comparisons/. Look for claims that conflict across pages (e.g., one page says X was founded in 2020, another says 2019). Report the conflicting claims, which pages contain them, and which sources support each claim. Ask the user which to trust.

2. **Orphan Pages**: Build a link graph — for each wiki page, collect all `related:` entries and inline links. Find pages with zero inbound links (exclude index.md, log.md, and overview.md from this check). Suggest adding them to related pages or removing them if obsolete.

3. **Stale Claims**: For each source summary in `wiki/sources/`, check if the corresponding raw file's modification date is newer than the page's `updated:` frontmatter date. If so, the source was modified after the summary was written — flag for re-ingestion.

4. **Missing Cross-References**: Check bidirectional completeness. For every page A that lists page B in `related:`, verify page B also lists page A. Report all one-directional links and offer to fix them.

5. **Stub Detection**: Scan all wiki page bodies for entity and concept names that appear multiple times across different pages but lack their own dedicated page. Report these as suggested new pages.

6. **Broken Links**: Verify all paths in `related:` frontmatter and all inline markdown links point to files that actually exist. Report any broken links.

After running all checks, present a summary table:
```
| Check             | Issues Found |
|-------------------|-------------|
| Contradictions    | 2           |
| Orphan Pages      | 1           |
| Stale Claims      | 0           |
| Missing Cross-Refs| 4           |
| Stubs             | 3           |
| Broken Links      | 0           |
```

Then offer to fix issues one at a time, starting with broken links (easiest) and working up to contradictions (requires judgment). Get user approval before each fix.

**How to verify**: `./tests/run_tests.sh` passes.

**Commit**: `Phase 5.1: Add Lint workflow to skill file`

---

## Phase 6: Polish and Documentation

**Goal**: Handle edge cases, update docs, add license, run final verification.

### Task 6.1: Add edge case handling

**Test first**: Create `tests/test_edge_cases.sh`

Assertions:
1. Skill file handles `raw/` existing without `wiki/` (grep for "inconsistent" or "missing")
2. Skill file handles empty `raw/` directory (grep for "no files" or "empty")
3. Skill file handles no user question and all files processed (grep for "menu" or "options")

**Modify**: `src/wikify.md` — add edge case instructions in the auto-detection section:
- If `raw/` exists but `wiki/` doesn't (or vice versa): warn the user about inconsistent state, offer to run Init to fix it
- If `raw/` is empty: tell the user to add sources and explain what file types are supported, with the subdirectory suggestions
- If all files are processed and no question/lint requested: present a menu of options (query, lint, add more sources)

**How to verify**: `./tests/run_tests.sh` passes.

**Commit**: `Phase 6.1: Add edge case handling to skill file`

### Task 6.2: Update README.md

**Modify**: `README.md`

Replace placeholder sections with full content:
- **Description**: What it is, the Karpathy pattern, the compilation insight
- **Installation**: `git clone`, `./scripts/install.sh`
- **Usage**: All four workflows with `/wikify` invocation examples
- **Supported File Types**: Table of types and how they're handled
- **Folder Structure**: ASCII diagram of the 3-layer architecture
- **Uninstall**: `./scripts/uninstall.sh`
- **License**: MIT

**How to verify**: README contains "Installation", "Usage", and "Uninstall" sections with actual content (not "Coming soon").

**Commit**: `Phase 6.2: Update README with full documentation`

### Task 6.3: Add LICENSE file

**File to create**: `LICENSE` — MIT License with Keith MacKay as copyright holder, year 2026.

**How to verify**: File exists and contains "MIT".

**Commit**: `Phase 6.3: Add MIT License`

### Task 6.4: Update docs/TESTING_GUIDELINES.md

The existing file is from a different project (HabitPeeps/Flutter). Replace with a brief testing doc for this project:
- Explain the shell-based test approach (grep assertions on file content)
- How to run tests: `./tests/run_tests.sh`
- How to run a single test: `./tests/run_tests.sh tests/test_foo.sh`
- How to add a new test: create `tests/test_name.sh`, source helpers, write assertions
- Why tests are grep-based: the deliverable is markdown, not code

**How to verify**: The file references shell tests, not Flutter.

**Commit**: `Phase 6.4: Update testing guidelines for this project`

### Task 6.5: Final test pass and install

1. Run `./tests/run_tests.sh` — all tests must pass
2. Run `./scripts/install.sh` — verify `~/.claude/commands/wikify.md` exists
3. Verify the installed file starts with `---` and contains `description:`
4. Run `git status` to confirm clean working tree

**Commit**: `Phase 6.5: Final test pass and verified install`

---

## Next Steps (Post-Launch Enhancements)

These are ideas for future improvements beyond the initial launch. Each is flagged with its source.

- **[Keith's idea]** Support for audio/video transcripts as source material (e.g., whisper transcripts dropped into `raw/`)
- **[Keith's idea]** Integration with Obsidian graph view — ensure wiki structure produces a useful graph
- **[Claude's idea]** `/wikify export` mode — generate a static HTML site from the wiki for sharing
- **[Claude's idea]** Confidence decay — automatically lower confidence on pages not validated against recent sources over time
- **[Claude's idea]** `/wikify diff` mode — show wiki changes since the last session (what pages were added/modified)
- **[Claude's idea]** `/wikify stats` mode — report wiki health metrics (page count, avg confidence, coverage by topic)
- **[Claude's idea]** Batch ingest mode — `--batch` flag for processing all new files without pausing for discussion
- **[Claude's idea]** Source type auto-detection in `raw/` — automatically sort files into subdirectories based on content analysis
- **[Keith's idea]** qmd integration — use Tobi Lutke's local search engine for large wikis that outgrow a single context window
- **[Claude's idea]** Wiki merge — combine two project wikis when projects converge
