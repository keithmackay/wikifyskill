# Wiki Schema

This file defines the structure, conventions, and workflows for this LLM-maintained knowledge wiki. Any human or LLM working with this project should read this file first.

## Project Structure

```
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
```

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

```markdown
## Sources
- [Source Title](sources/source-title.md) — type: source-summary, confidence: high

## Concepts
- [Concept Name](concepts/concept-name.md) — type: concept, confidence: medium

## Entities
- [Entity Name](entities/entity-name.md) — type: entity, confidence: high

## Comparisons
- [Comparison Title](comparisons/comparison-title.md) — type: comparison, confidence: medium
```

Updated on every ingest operation.

### log.md

An append-only chronological record of all processing activity:

```markdown
## [2026-04-15] ingest | Article Title
- Created: sources/article-title.md
- Created: concepts/new-concept.md
- Updated: entities/existing-entity.md
```

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
