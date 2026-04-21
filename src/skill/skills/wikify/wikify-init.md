# wikify — Init Workflow

Create the full wiki folder structure and schema files in the current directory.

## Step 0: Determine Categories

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

## Step 1: Create Directories

Use the Bash tool to create all directories. The `raw/` subdirs are always the same. The `wiki/` subdirs come from the category list plus `sources`.

```bash
mkdir -p raw/articles raw/papers raw/repos raw/data raw/images raw/assets
mkdir -p wiki/sources wiki/<cat1> wiki/<cat2> ...
```

## Step 2: Create WIKI_SCHEMA.md

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

## Step 3: Create wiki/index.md

Create `wiki/index.md` with one section per category, starting with Sources:

```markdown
# Wiki Index

A catalog of all pages in this knowledge wiki, organized by type.

## Sources

*No sources ingested yet. Add files to `raw/` and run wikify to begin.*

## <Cat1 title-cased>

*No pages yet.*

## <Cat2 title-cased>

*No pages yet.*
```

## Step 4: Create wiki/log.md

```markdown
# Processing Log

Chronological record of all wiki processing activity.
```

## Step 5: Create wiki/overview.md

```markdown
# Wiki Overview

*This wiki has just been initialized. Add source files to `raw/` and run wikify to begin building the knowledge base.*
```

## Step 6: Report

Tell the user what was created, listing the actual category folders used.
