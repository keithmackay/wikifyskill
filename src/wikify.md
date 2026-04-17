---
description: Build and maintain an LLM-compiled knowledge wiki (Karpathy pattern). Auto-detects context and runs Init, Ingest, Query, or Lint.
---

# /wikify — LLM Knowledge Wiki

> **build-site.sh** is at `~/.claude/skills/wikify/scripts/build-site.sh`. Run it from any wiki project root to generate the D3 website:
> ```bash
> python3 ~/.claude/skills/wikify/scripts/build-site.sh wiki website
> ```

You are running the wikify skill. Follow these instructions exactly.

## Step 1: Detect Context

Examine the current working directory to determine which workflow to run. Use the Bash tool to check for the existence of directories and files.

**Check these conditions in order:**

1. **Lint requested**: If the user typed text after `/wikify` and that text contains the word "lint", go to **Lint Workflow**.

2. **Learning plan requested**: If the user typed text after `/wikify` and that text contains the phrase "learning_plan" or "learning plan", go to **Learning Plan Workflow**.

3. **Query requested**: If the user typed text after `/wikify` (and it's not "lint" or "learning_plan"), go to **Query Workflow**.

4. **Init needed**: If `WIKI_SCHEMA.md` does not exist in the current directory, go to **Init Workflow**.

5. **Inconsistent state**: If only one of `raw/` or `wiki/` exists (but not both), warn the user: "Found [raw/|wiki/] but not [wiki/|raw/]. This looks like an incomplete setup. Would you like to run Init to fix this?" If yes, go to **Init Workflow**.

6. **Ingest available**: If both `raw/` and `wiki/` exist, scan for unprocessed files (see Ingest Workflow Step 1). If new files are found, go to **Ingest Workflow**.

7. **Nothing to do**: If both directories exist and all files are processed, present this menu:
   - "All sources are processed. What would you like to do?"
   - **Query**: "Ask a question about the wiki (e.g., `/wikify what is X?`)"
   - **Lint**: "Run a health check (e.g., `/wikify lint`)"
   - **Add sources**: "Add new files to `raw/` and run `/wikify` again"

Report which workflow was detected and ask the user to confirm before proceeding.

---

## Init Workflow

Create the full wiki folder structure and schema files in the current directory.

### Step 0: Determine Categories

Before creating anything, scan `raw/` for existing files to propose domain-appropriate categories.

**Auto-propose categories from raw docs:**

1. Use Glob to list all files under `raw/` recursively.
2. Read the filenames and (if text files) skim the first 20–50 lines of up to 5 files to detect the domain.
3. Based on what you find, propose a tailored category list. Examples by domain:
   - Research/academic corpus → `concepts`, `entities`, `comparisons`, `methods`
   - Fiction/narrative → `characters`, `locations`, `artifacts`, `factions`, `events`
   - Technical/software → `concepts`, `tools`, `apis`, `patterns`
   - Business/strategy → `concepts`, `companies`, `people`, `frameworks`
   - No files found → use default: `concepts`, `entities`, `comparisons`

Present your proposed list with a one-line rationale for each category based on what you observed in the raw files. Then say:

"These categories are based on the content I found in `raw/`. Confirm this list or give me your own."

Wait for the user's response. Use their confirmed list for all subsequent steps. Always include `sources` regardless of what the user says — it is required and always uses `type: source-summary`.

Store this list as the **category list** for the rest of Init. Each category name is both the subfolder name and the `type` value used in frontmatter for pages in that folder.

### Step 1: Create Directories

Use the Bash tool to create all directories. The `raw/` subdirs are always the same. The `wiki/` subdirs come from the category list plus `sources`.

```bash
mkdir -p raw/articles raw/papers raw/repos raw/data raw/images raw/assets
mkdir -p wiki/sources wiki/<cat1> wiki/<cat2> ...
```

### Step 2: Create WIKI_SCHEMA.md

Use the Write tool to create `WIKI_SCHEMA.md` with content tailored to the actual categories chosen. The **Categories** section is the authoritative record — all ingest and lint workflows read it.

```markdown
# Wiki Schema

This file defines the structure, conventions, and workflows for this LLM-maintained knowledge wiki. Any human or LLM working with this project should read this file first.

## Categories

The `sources` folder is always present and holds one summary page per raw source file (`type: source-summary`). All other categories are listed below — each folder name is the exact value used in the `type` frontmatter field of pages stored there.

- `sources/` → type: `source-summary` *(required, one per raw source file)*
- `<cat1>/` → type: `<cat1>`
- `<cat2>/` → type: `<cat2>`
- ...

## Project Structure

\```
raw/                          # Layer 1: Immutable source material (read-only)
├── articles/
├── papers/
├── repos/
├── data/
├── images/
└── assets/

wiki/                         # Layer 2: LLM-maintained knowledge base
├── index.md                  # Content catalog
├── log.md                    # Chronological processing log
├── overview.md               # High-level wiki summary
├── sources/                  # Source summary pages
├── <cat1>/
├── <cat2>/
└── ...

WIKI_SCHEMA.md                # This file
\```

**`raw/`** is read-only. The LLM reads from these files but never modifies them.

**`wiki/`** is LLM-owned. The LLM creates, updates, and maintains all pages.

## Page Types

### source-summary

One per raw source file. Lives in `wiki/sources/`. Summarizes key takeaways, lists extracted entities and concepts, and links back to the raw file. Created during ingest.

### <cat1> (and all other categories)

Pages of this type live in `wiki/<cat1>/`. The type value in frontmatter is exactly `<cat1>` — the folder name.

## Frontmatter Schema

Every wiki page must have YAML frontmatter with these fields:

\```yaml
---
title: Page Title
type: source-summary | <cat1> | <cat2> | ...
sources:
  - ../raw/articles/source-file.md
related:
  - <cat1>/related-page.md
  - sources/related-source.md
confidence: high | medium | low
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
\```

**Field definitions:**

- **title:** Human-readable page title
- **type:** Exactly matches the folder name where the page lives (exception: `sources/` uses `source-summary`)
- **sources:** List of relative paths to raw files this page draws from
- **related:** List of relative paths to other wiki pages that are related
- **confidence:** `high` (multiple corroborating sources), `medium` (single source), `low` (speculative)
- **created/updated:** YYYY-MM-DD

## Naming Conventions

- Filenames use lowercase kebab-case slugs derived from the title
- No spaces, no uppercase, no special characters beyond hyphens

## Special Files

### index.md

Catalog organized by category. One section per category (including Sources).

### log.md

Append-only chronological record:
\```markdown
## [YYYY-MM-DD] ingest | Source Title
- Source: raw/path/to/file.ext
- Created: sources/slug.md
- Created: <cat1>/new-page.md
\```

### overview.md

High-level summary of wiki scope, themes, and major findings.
```

Substitute the actual category names throughout. The Categories section must be kept accurate — it is machine-read by the ingest and lint workflows.

### Step 3: Create wiki/index.md

Create `wiki/index.md` with one section per category, starting with Sources:

```markdown
# Wiki Index

A catalog of all pages in this knowledge wiki, organized by type.

## Sources

*No sources ingested yet. Add files to `raw/` and run `/wikify` to begin.*

## <Cat1 title-cased>

*No pages yet.*

## <Cat2 title-cased>

*No pages yet.*
```

### Step 4: Create wiki/log.md

```markdown
# Processing Log

Chronological record of all wiki processing activity.
```

### Step 5: Create wiki/overview.md

```markdown
# Wiki Overview

*This wiki has just been initialized. Add source files to `raw/` and run `/wikify` to begin building the knowledge base.*
```

### Step 6: Report

Tell the user what was created, listing the actual category folders used.

---

## Ingest Workflow

### Step 0: Read Categories from WIKI_SCHEMA.md

**Before doing anything else**, read `WIKI_SCHEMA.md` and extract the Categories section. Parse each line of the form `- \`<folder>/\` → type: \`<type>\`` to build the category map.

This map drives all file placement and frontmatter type values in Steps 4 and 5. Never use hardcoded folder names — always use what WIKI_SCHEMA.md says.

### Step 1: Discover Unprocessed Files

Use the Glob tool to scan `raw/` recursively for all files:

```
pattern: raw/**/*
```

Filter out system files: `.DS_Store`, `.gitkeep`, `Thumbs.db`, and any files starting with `.`.

Check each source summary page in `wiki/sources/` — read their `sources:` frontmatter to find which raw files have already been processed.

Any file in `raw/` whose path does not appear in any source summary's `sources:` frontmatter is unprocessed.

Report the count and list of unprocessed files. Ask: "Which file would you like to process first?" or "Process them in order?"

Process one file at a time. After each file, ask whether to continue with the next.

### Step 2: Read the Source

Read the file using the appropriate method based on file extension:

| Extension | Method |
|-----------|--------|
| `.md`, `.txt`, `.html` | Use the Read tool directly |
| `.csv`, `.json`, `.yaml`, `.yml` | Use the Read tool directly |
| `.py`, `.js`, `.ts`, `.rs`, `.go`, `.java`, `.c`, `.cpp`, `.h`, `.rb`, `.sh` | Use the Read tool directly |
| `.pdf` | Use the `read_pdf_content` MCP tool |
| `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg` | Use the Read tool (Claude sees images via vision) |
| Directories in `raw/repos/` | Read README.md first, then key source files |
| Other | Report the file type and ask the user for a text summary or to convert it |

### Step 3: Detect Domain and Present Summary

**First, detect the domain of the source material.**

| Domain | Signals |
|--------|---------|
| **Fiction / Narrative** | Novel, story, chapter headings, character names, dialogue |
| **Technical / Code** | Imports, function names, APIs, architecture diagrams |
| **Research / Academic** | Citations, abstracts, methodology sections |
| **General** | Mixed or unclear |

**Extraction mandate: Be exhaustive, not selective.**

The rule: **if it has a proper name, it gets a page.** Do not filter by importance.

After reading the source, present the user with:

1. **Key Takeaways** — Comprehensive bullet list
2. **Identified items per category** — For each category in the wiki (from WIKI_SCHEMA.md), list every item from the source that belongs there. Be exhaustive.
3. **Identified source-summary** — What the source summary page will contain
4. **Contradictions** — Claims that conflict with existing wiki pages
5. **Suggested Wiki Pages** — Complete list organized by category

Then ask: "Any additional context or direction for how to file this? Are there any items I missed?"

Wait for the user's response before proceeding.

### Step 4: Create and Update Wiki Pages

**Read the category map from WIKI_SCHEMA.md** (Step 0 result) to determine all file paths and type values.

**Source summary page** (always create):
- Path: `wiki/sources/<kebab-case-slug>.md`
- Frontmatter `type: source-summary`
- Body: summary paragraph, key takeaways, links to related wiki pages

**Pages for each category** (create or update):
- Path: `wiki/<folder>/<slug>.md` where `<folder>` comes from the category map
- Frontmatter `type: <type>` where `<type>` comes from the category map
- Check for an existing page before creating — if found, read it, append new information, add the raw file to `sources:`, update `updated:`
- Create a page for every item identified in Step 3 for that category. Do not omit anything.

All pages must use lowercase kebab-case filenames and the full frontmatter schema.

### Step 5: Update Index and Log

**Update `wiki/index.md`**:
- Read the current index
- Add entries for all newly created pages under the matching category section
- The section names come from WIKI_SCHEMA.md categories — do not add or invent sections not in the schema
- Format: `- [Title](relative-path) — type: <type>, confidence: <level>`
- Keep entries sorted alphabetically within each section
- Never remove a section heading — use `*None yet.*` as placeholder

**Append to `wiki/log.md`**:
```markdown
## [YYYY-MM-DD] ingest | Source Title
- Source: raw/path/to/file.ext
- Created: sources/slug.md
- Created: <cat>/new-page.md (if applicable)
- Updated: <cat>/existing-page.md (if applicable)
```

### Step 6: Cross-Reference Pass

Read all pages created or modified during this ingest. For each page:

1. Check the `related:` frontmatter list
2. For every page A that lists page B in `related:`, verify page B also lists page A
3. If page B doesn't link back, edit page B to add page A to its `related:` list
4. Update the `updated:` date on any page modified during this pass

### Step 7: Continue or Stop

If there are more unprocessed files, ask: "Process the next file (<filename>), or stop here?"

If no more unprocessed files remain: "All sources processed. Run `/wikify` with a question to query the wiki, or `/wikify lint` for a health check."

---

## Query Workflow

### Step 1: Parse the Question

The user's question is the text they typed after `/wikify`. Extract the full question.

### Step 2: Gather Context

1. Read `wiki/overview.md` for high-level context
2. Read `wiki/index.md` for the full page catalog
3. Identify relevant pages by matching the question against page titles and descriptions

### Step 3: Read Relevant Pages

Read the identified relevant wiki pages (typically 3-10 depending on scope). Prioritize:
- Pages whose titles closely match the question topic
- Non-source pages over source summaries (they synthesize across sources)

### Step 4: Synthesize Answer

Produce a comprehensive answer grounded in wiki content:
- Use inline citations: `(see [Page Title](wiki/path/page.md))`
- Note confidence levels for key claims
- Structure clearly with headings if complex

### Step 5: Identify Gaps

After answering, note areas where information is thin or missing and suggest source types that would fill the gaps.

### Step 6: Offer to Save

Ask: "Should I save this answer as a wiki page?"

If yes:
1. Ask which category fits best (from WIKI_SCHEMA.md categories)
2. Create the page with full frontmatter
3. Update `wiki/index.md`
4. Append to `wiki/log.md` with a `query` action type
5. Run a cross-reference pass on the new page

---

## Lint Workflow

### Step 0: Read Categories from WIKI_SCHEMA.md

Read `WIKI_SCHEMA.md` and extract the full category map before running any checks. All folder paths used in checks below come from this map — never hardcode folder names.

Run all six health checks, then present results and offer fixes.

### Check 1: Contradictions

Read all wiki pages across all category folders (from WIKI_SCHEMA.md). Look for claims that conflict across pages.

For each contradiction found, report:
- The conflicting claims (quote both)
- Which pages contain them
- Which raw sources support each claim

Ask the user which claim to trust, then update the incorrect page.

### Check 2: Orphan Pages

Build a link graph across the wiki:
- For each page, collect all paths from `related:` frontmatter and all inline markdown links
- Find pages that have zero inbound links from any other page

Exclude `wiki/index.md`, `wiki/log.md`, and `wiki/overview.md` from this check.

For each orphan, suggest adding it to related pages or flagging it for removal.

### Check 3: Stale Claims

For each source summary in `wiki/sources/`:
1. Read the `sources:` frontmatter to find the raw file path
2. Check the raw file's modification timestamp (`ls -la` via Bash)
3. Compare against the page's `updated:` date
4. If the raw file is newer, flag for re-ingestion

### Check 4: Missing Cross-References

For every wiki page A listing page B in `related:`:
- Read page B and check if page A appears in B's `related:` list
- Report all one-directional links and offer to fix them automatically

### Check 5: Stub Detection

Scan all wiki page bodies for proper nouns and concept terms that:
- Appear in 2 or more different pages
- Do not have their own dedicated page in any category folder (from WIKI_SCHEMA.md)

Report potential stub pages and offer to create them.

### Check 6: Broken Links

For every wiki page:
- Check all paths in `related:` frontmatter — verify each file exists
- Check all inline markdown links — verify each target exists
- Check all `sources:` frontmatter paths — verify each raw file exists

### Lint Summary

```
| Check               | Issues Found |
|---------------------|-------------|
| Contradictions      | X           |
| Orphan Pages        | X           |
| Stale Claims        | X           |
| Missing Cross-Refs  | X           |
| Stubs               | X           |
| Broken Links        | X           |
```

Offer to fix issues one at a time, starting with broken links and working up to contradictions. Get user approval before each fix.

---

## Learning Plan Workflow

Generate or regenerate `wiki/learning_plan.md` — a structured, dependency-ordered reading guide for the wiki's domain.

### Step 1: Read Categories and All Concept Pages

Read `WIKI_SCHEMA.md` to get the category list. Then read all pages in every category folder (not `sources/`). Also read `wiki/overview.md` for domain framing.

### Step 2: Identify Bedrock Concepts

From the pages you've read, identify **bedrock concepts** — ideas that must be understood before other topics make sense. A concept is bedrock if:

- Multiple other concepts explicitly depend on it (appear in their `related:` or body text)
- It is a prerequisite in the academic sense (e.g., probability theory before topic modeling)
- It is defined and used across more than half the pages

List these as **Tier 1** (learn first).

### Step 3: Build a Dependency Graph

For each remaining concept and entity page, determine what it requires from Tier 1 (and from each other). Group into tiers:

- **Tier 1** — Bedrock: no prerequisites within the wiki
- **Tier 2** — Builds on Tier 1 only
- **Tier 3** — Builds on Tier 1 + 2
- **Tier 4** — Advanced / integrative: requires most of the above

Use the `related:` frontmatter and body content of each page to determine dependencies. When a page explicitly references another concept, that referenced concept is a prerequisite.

### Step 4: Write `wiki/learning_plan.md`

Create the file with:

```markdown
---
title: Learning Plan
type: learning-plan
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Learning Plan

A dependency-ordered guide to mastering this wiki's domain. Start at Tier 1 and progress through each tier before advancing — each page builds on those before it.

## How to Use This Plan

Each item links to a wiki page. Read pages within a tier in any order; complete a tier before moving to the next.

## Tier 1 — Bedrock Concepts

*These are the foundational ideas everything else builds on. Start here.*

1. [[page-slug|Page Title]] — one-sentence description of why this is foundational

## Tier 2 — Core Methods

*Requires Tier 1. These concepts directly apply or extend the bedrock ideas.*

1. [[page-slug|Page Title]] — one-sentence description, noting which Tier 1 concept it builds on

## Tier 3 — Applied Techniques

*Requires Tier 1–2. These are specific techniques, tools, or systems.*

...

## Tier 4 — Advanced & Integrative

*Requires Tier 1–3. These combine multiple prior concepts or represent the current research frontier.*

...

## Quick Reference: Dependency Map

A compact view of which concepts depend on which:

| Concept | Depends On |
|---------|-----------|
| Page Title | [[prereq-1]], [[prereq-2]] |
...
```

Use Obsidian-style `[[page-slug|Display Title]]` links throughout. Pages outside the wiki (foundational math, external tools, etc.) can be referenced as plain text rather than wiki links.

### Step 5: Update Index and Log

- Add `learning_plan.md` to `wiki/index.md` under a new `## Learning Resources` section (or append it if that section exists)
- Append to `wiki/log.md`:
```markdown
## [YYYY-MM-DD] learning_plan | Generated Learning Plan
- Created: wiki/learning_plan.md
- Tiers: X concepts across Y tiers
```

### Step 6: Build Website

After writing `learning_plan.md`, run the build script to regenerate the website with the learning plan included:

```bash
python3 ~/.claude/skills/wikify/scripts/build-site.sh wiki website
```

Run this from the wiki project root directory. The learning plan will appear as a "Learning Plan" link in the site nav, linking directly to its page.

### Step 7: Confirm

Report: "Learning plan created at `wiki/learning_plan.md` with X pages across Y tiers. Website rebuilt at `website/`." Offer to regenerate if the user wants different tier groupings.
