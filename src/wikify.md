---
description: Build and maintain an LLM-compiled knowledge wiki (Karpathy pattern). Auto-detects context and runs Init, Ingest, Query, or Lint.
---

# /wikify — LLM Knowledge Wiki

You are running the wikify skill. Follow these instructions exactly.

## Step 1: Detect Context

Examine the current working directory to determine which workflow to run. Use the Bash tool to check for the existence of directories and files.

**Check these conditions in order:**

1. **Lint requested**: If the user typed text after `/wikify` and that text contains the word "lint", go to **Lint Workflow**.

2. **Query requested**: If the user typed text after `/wikify` (and it's not "lint"), go to **Query Workflow**.

3. **Init needed**: If `WIKI_SCHEMA.md` does not exist in the current directory, go to **Init Workflow**.

4. **Inconsistent state**: If only one of `raw/` or `wiki/` exists (but not both), warn the user: "Found [raw/|wiki/] but not [wiki/|raw/]. This looks like an incomplete setup. Would you like to run Init to fix this?" If yes, go to **Init Workflow**.

5. **Ingest available**: If both `raw/` and `wiki/` exist, scan for unprocessed files (see Ingest Workflow Step 1). If new files are found, go to **Ingest Workflow**.

6. **Nothing to do**: If both directories exist and all files are processed, present this menu:
   - "All sources are processed. What would you like to do?"
   - **Query**: "Ask a question about the wiki (e.g., `/wikify what is X?`)"
   - **Lint**: "Run a health check (e.g., `/wikify lint`)"
   - **Add sources**: "Add new files to `raw/` and run `/wikify` again"

Report which workflow was detected and ask the user to confirm before proceeding.

---

## Init Workflow

Create the full wiki folder structure and schema files in the current directory.

### Step 1: Create Directories

Use the Bash tool to create all directories:

```bash
mkdir -p raw/articles raw/papers raw/repos raw/data raw/images raw/assets
mkdir -p wiki/concepts wiki/entities wiki/sources wiki/comparisons
```

### Step 2: Create WIKI_SCHEMA.md

Use the Write tool to create `WIKI_SCHEMA.md` in the current directory with the following content:

```markdown
# Wiki Schema

This file defines the structure, conventions, and workflows for this LLM-maintained knowledge wiki. Any human or LLM working with this project should read this file first.

## Project Structure

\```
raw/                          # Layer 1: Immutable source material (read-only)
├── articles/                 # Web-clipped articles, blog posts
├── papers/                   # Academic papers, whitepapers
├── repos/                    # Source code repositories
├── data/                     # CSV, JSON, YAML data files
├── images/                   # Diagrams, screenshots, photos
└── assets/                   # Other files (audio, video, etc.)

wiki/                         # Layer 2: LLM-maintained knowledge base
├── index.md                  # Content catalog (all pages listed by category)
├── log.md                    # Chronological processing log
├── overview.md               # High-level wiki summary and key findings
├── concepts/                 # Concept pages (ideas, techniques, patterns)
├── entities/                 # Entity pages (people, orgs, tools, projects)
├── sources/                  # Source summary pages (one per raw file)
└── comparisons/              # Comparison pages (side-by-side analysis)

WIKI_SCHEMA.md                # Layer 3: This file (schema and conventions)
\```

**`raw/`** is read-only. The LLM reads from these files but never modifies them. This is the single source of truth for all knowledge in the wiki.

**`wiki/`** is LLM-owned. The LLM creates, updates, and maintains all pages. Humans should not edit wiki pages directly — instead, add sources to `raw/` and let the LLM process them.

## Page Types

### source-summary

One per raw source file. Lives in `wiki/sources/`. Summarizes key takeaways, lists extracted entities and concepts, and links back to the raw file. Created during ingest.

### concept

One per significant idea, technique, pattern, or theory. Lives in `wiki/concepts/`. Synthesizes information across multiple sources. Updated whenever a new source touches the concept.

### entity

One per named thing — person, organization, tool, project, framework. Lives in `wiki/entities/`. Aggregates all mentions and context from across sources.

### comparison

Side-by-side analysis of alternatives, tools, or approaches. Lives in `wiki/comparisons/`. Uses tables for structured trade-off analysis. Only created when explicitly warranted by the source material.

## Frontmatter Schema

Every wiki page must have YAML frontmatter with these fields:

\```yaml
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
\```

**Field definitions:**

- **title:** Human-readable page title
- **type:** One of `concept`, `entity`, `source-summary`, or `comparison`
- **sources:** List of relative paths to raw files this page draws from
- **related:** List of relative paths to other wiki pages that are related
- **confidence:** How well-supported the claims are — `high` (multiple corroborating sources), `medium` (single source or partially corroborated), `low` (speculative or from a single unreliable source)
- **created:** Date the page was first created (YYYY-MM-DD)
- **updated:** Date the page was last modified (YYYY-MM-DD)

## Naming Conventions

- Filenames use lowercase kebab-case slugs derived from the title
- Examples: `transformer-architecture.md`, `andrej-karpathy.md`, `react-vs-vue.md`
- No spaces, no uppercase, no special characters beyond hyphens
- Slugs should be descriptive but concise

## Special Files

### index.md

A categorical catalog of all wiki pages. Organized into sections by type:

\```markdown
## Sources
- [Source Title](sources/source-title.md) — type: source-summary, confidence: high

## Concepts
- [Concept Name](concepts/concept-name.md) — type: concept, confidence: medium

## Entities
- [Entity Name](entities/entity-name.md) — type: entity, confidence: high

## Comparisons
- [Comparison Title](comparisons/comparison-title.md) — type: comparison, confidence: medium
\```

Updated on every ingest operation.

### log.md

An append-only chronological record of all processing activity:

\```markdown
## [2026-04-15] ingest | Article Title
- Created: sources/article-title.md
- Created: concepts/new-concept.md
- Updated: entities/existing-entity.md
\```

Each entry uses the format `## [YYYY-MM-DD] ingest | Source Title` followed by a bullet list of pages created or updated.

### overview.md

A high-level summary of the wiki's scope, key themes, and major findings. Updated periodically as the wiki grows. Serves as the entry point for understanding what knowledge has been compiled.

## Workflows

### Ingest

When new source files appear in `raw/`, the Ingest workflow:
1. Identifies unprocessed files by comparing `raw/` contents against `log.md`
2. Reads each source file using the appropriate method for its type
3. Presents a summary and discusses takeaways with the human
4. Creates a source summary page and updates related concept/entity/comparison pages
5. Updates `index.md` and appends to `log.md`
6. Ensures bidirectional cross-references across all affected pages

### Query

When the human asks a question, the Query workflow:
1. Reads `index.md` and `overview.md` to identify relevant pages
2. Reads the relevant pages and synthesizes an answer with citations
3. Flags knowledge gaps and suggests sources to fill them
4. Offers to save the answer as a new wiki page

### Lint

The Lint workflow runs six health checks:
1. **Contradictions** — Conflicting claims across pages
2. **Orphan pages** — Pages with zero inbound links
3. **Stale claims** — Source files modified after their summary was written
4. **Missing cross-references** — One-directional links that should be bidirectional
5. **Stub detection** — Concepts mentioned but lacking dedicated pages
6. **Broken links** — References to files that no longer exist
```

### Step 3: Create wiki/index.md

Use the Write tool to create `wiki/index.md`:

```markdown
# Wiki Index

A catalog of all pages in this knowledge wiki, organized by type.

## Sources

*No sources ingested yet. Add files to `raw/` and run `/wikify` to begin.*

## Concepts

*No concept pages yet.*

## Entities

*No entity pages yet.*

## Comparisons

*No comparison pages yet.*
```

### Step 4: Create wiki/log.md

Use the Write tool to create `wiki/log.md`:

```markdown
# Processing Log

Chronological record of all wiki processing activity.
```

### Step 5: Create wiki/overview.md

Use the Write tool to create `wiki/overview.md`:

```markdown
# Wiki Overview

*This wiki has just been initialized. Add source files to `raw/` and run `/wikify` to begin building the knowledge base.*
```

### Step 6: Report

Tell the user:

"Wiki structure initialized. Here's what was created:
- `raw/` — 6 subdirectories for your source material (articles, papers, repos, data, images, assets)
- `wiki/` — 4 subdirectories for wiki pages (concepts, entities, sources, comparisons)
- `wiki/index.md` — Empty content catalog
- `wiki/log.md` — Empty processing log
- `wiki/overview.md` — Placeholder overview
- `WIKI_SCHEMA.md` — Schema and conventions reference

**Next step**: Add source files to `raw/` (markdown, PDFs, images, code, data files) and run `/wikify` again to begin ingesting."

---

## Ingest Workflow

### Step 1: Discover Unprocessed Files

Use the Glob tool to scan `raw/` recursively for all files:

```
pattern: raw/**/*
```

Filter out system files: `.DS_Store`, `.gitkeep`, `Thumbs.db`, and any files starting with `.`.

Then read `wiki/log.md` and extract all source file paths. Look for lines matching the pattern `## [YYYY-MM-DD] ingest | ` — these are ingest entries. Within each ingest entry, look for the raw file path referenced in the source summary page that was created.

Also check each source summary page in `wiki/sources/` — read their `sources:` frontmatter to find which raw files have already been processed.

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
| Directories in `raw/repos/` | Read README.md first, then key source files (entry points, config) |
| Other | Report the file type and ask the user for a text summary or to convert it |

### Step 3: Present Summary and Discuss

After reading the source, present the user with:

1. **Key Takeaways** — 3-5 bullet points summarizing the most important information
2. **Identified Entities** — People, organizations, tools, projects, frameworks mentioned
3. **Identified Concepts** — Techniques, patterns, theories, ideas introduced or discussed
4. **Contradictions** — Read existing wiki pages related to the identified entities and concepts. Note any claims that conflict with information in this source.
5. **Suggested Wiki Pages** — List pages to create or update

Then ask: "Any additional context or direction for how to file this?"

Wait for the user's response before proceeding. The user might correct misunderstandings, add context, emphasize certain aspects, or just say "looks good."

### Step 4: Create and Update Wiki Pages

For each page, use the Write tool (for new pages) or the Edit tool (for updating existing pages).

**Source summary page** (always create):
- Path: `wiki/sources/<kebab-case-slug>.md`
- Include full YAML frontmatter (title, type: source-summary, sources, related, confidence, created, updated)
- Body: summary paragraph, key takeaways as bullets, notable data points, links to related wiki pages

**Concept pages** (create or update):
- Check `wiki/concepts/` for an existing page matching the concept
- If found: read it, append new information from this source, add the raw file to `sources:` frontmatter, update the `updated:` date
- If not found: create a new page in `wiki/concepts/<slug>.md` with full frontmatter

**Entity pages** (create or update):
- Same create-or-update pattern in `wiki/entities/`
- Check for existing pages before creating new ones

**Comparison pages** (create only when warranted):
- Only create when the source explicitly compares alternatives, tools, or approaches
- Use tables for side-by-side analysis in the page body
- Path: `wiki/comparisons/<slug>.md`

All pages must use lowercase kebab-case filenames and the full frontmatter schema.

### Step 5: Update Index and Log

**Update `wiki/index.md`**:
- Read the current index
- Add entries for all newly created pages under the appropriate category section (Sources, Concepts, Entities, Comparisons)
- Format: `- [Title](relative-path) — type: <type>, confidence: <level>`
- Keep entries sorted alphabetically within each section

**Append to `wiki/log.md`**:
- Add an entry in the format:
```markdown
## [YYYY-MM-DD] ingest | Source Title
- Source: raw/path/to/file.ext
- Created: sources/slug.md
- Created: concepts/new-concept.md (if applicable)
- Updated: entities/existing-entity.md (if applicable)
```
- Use today's date

### Step 6: Cross-Reference Pass

Read all pages that were created or modified during this ingest. For each page:

1. Check the `related:` frontmatter list
2. For every page A that lists page B in `related:`, verify page B also lists page A
3. If page B doesn't link back to page A, edit page B to add page A to its `related:` list
4. Update the `updated:` date on any page modified during this pass

This ensures all cross-references are bidirectional.

### Step 7: Continue or Stop

If there are more unprocessed files in `raw/`, ask: "Process the next file (<filename>), or stop here?"

If no more unprocessed files remain, report: "All sources processed. Run `/wikify` with a question to query the wiki, or `/wikify lint` for a health check."

---

## Query Workflow

### Step 1: Parse the Question

The user's question is the text they typed after `/wikify`. Extract the full question.

### Step 2: Gather Context

1. Read `wiki/overview.md` for high-level context about the wiki's scope
2. Read `wiki/index.md` for the full page catalog
3. Identify relevant pages by matching the question against page titles, types, and descriptions in the index

### Step 3: Read Relevant Pages

Read the identified relevant wiki pages (typically 3-10 pages depending on the question scope). Prioritize:
- Pages whose titles closely match the question topic
- Concept pages over source summaries (they synthesize across sources)
- Comparison pages when the question involves trade-offs or alternatives

### Step 4: Synthesize Answer

Produce a comprehensive answer grounded in wiki content:
- Use inline citations in the format `(see [Page Title](wiki/path/page.md))` — link to wiki pages, not raw sources
- Note confidence levels — if key claims come from low-confidence pages, say so
- Structure the answer clearly with headings if the topic is complex

### Step 5: Identify Gaps

After answering, check whether the question touches topics not well-covered in the wiki:
- Mention any areas where information is thin or missing
- Suggest specific types of sources that would fill the gaps (e.g., "a paper on X" or "documentation for Y")

### Step 6: Offer to Save

Ask the user: "Should I save this answer as a wiki page?"

If yes:
1. Ask which type fits best (concept, comparison, or entity)
2. Create the page with full YAML frontmatter
3. Update `wiki/index.md` with the new entry
4. Append to `wiki/log.md` with a `query` action type
5. Run a cross-reference pass on the new page

---

## Lint Workflow

Run all six health checks on the wiki, then present results and offer fixes.

### Check 1: Contradictions

Read all wiki pages in `wiki/concepts/`, `wiki/entities/`, and `wiki/comparisons/`. Look for claims that conflict across pages — for example, one page says a tool was released in 2020 while another says 2019, or one page recommends approach A while another recommends the opposite.

For each contradiction found, report:
- The conflicting claims (quote both)
- Which pages contain them
- Which raw sources support each claim

Ask the user which claim to trust, then update the incorrect page.

### Check 2: Orphan Pages

Build a link graph across the wiki:
- For each page, collect all paths from `related:` frontmatter and all inline markdown links
- Find pages that have zero inbound links from any other page

Exclude `wiki/index.md`, `wiki/log.md`, and `wiki/overview.md` from this check (they are entry points, not linked targets).

For each orphan, suggest either adding it to related pages or flagging it for removal.

### Check 3: Stale Claims

For each source summary in `wiki/sources/`:
1. Read the `sources:` frontmatter to find the raw file path
2. Check the raw file's modification timestamp (use `ls -la` via Bash)
3. Compare against the page's `updated:` frontmatter date
4. If the raw file is newer, flag the source summary for re-ingestion

Report all stale pages and offer to re-ingest the updated sources.

### Check 4: Missing Cross-References

For every wiki page A that lists page B in its `related:` frontmatter:
- Read page B and check if page A appears in B's `related:` list
- If not, this is a one-directional link that should be bidirectional

Report all missing backlinks and offer to fix them automatically.

### Check 5: Stub Detection

Scan all wiki page bodies (not frontmatter) for proper nouns, tool names, and concept terms that:
- Appear in 2 or more different pages
- Do not have their own dedicated page in `wiki/concepts/` or `wiki/entities/`

Report these as potential stub pages and offer to create them.

### Check 6: Broken Links

For every wiki page:
- Check all paths in `related:` frontmatter — verify each file exists
- Check all inline markdown links — verify each target exists
- Check all `sources:` frontmatter paths — verify each raw file exists

Report all broken links with the page and the broken path.

### Lint Summary

After all checks, present a summary table:

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

Then offer to fix issues one at a time, starting with broken links (easiest, mechanical fixes) and working up to contradictions (require judgment). Get user approval before each fix.
