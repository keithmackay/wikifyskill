# wikify — Learning Plan Workflow

Generate or regenerate `wiki/learning_plan.md` — a structured, dependency-ordered reading guide for the wiki's domain.

## Step 1: Read Categories and All Concept Pages

Read `WIKI_SCHEMA.md` to get the category list. Then read all pages in every category folder (not `sources/`). Also read `wiki/overview.md` for domain framing.

## Step 2: Identify Bedrock Concepts

From the pages you've read, identify **bedrock concepts** — ideas that must be understood before other topics make sense. A concept is bedrock if:

- Multiple other concepts explicitly depend on it (appear in their `related:` or body text)
- It is a prerequisite in the academic sense (e.g., probability theory before topic modeling)
- It is defined and used across more than half the pages

List these as **Tier 1** (learn first).

## Step 3: Build a Dependency Graph

For each remaining concept and entity page, determine what it requires from Tier 1 (and from each other). Group into tiers:

- **Tier 1** — Bedrock: no prerequisites within the wiki
- **Tier 2** — Builds on Tier 1 only
- **Tier 3** — Builds on Tier 1 + 2
- **Tier 4** — Advanced / integrative: requires most of the above

Use the `related:` frontmatter and body content of each page to determine dependencies. When a page explicitly references another concept, that referenced concept is a prerequisite.

## Step 4: Write `wiki/learning_plan.md`

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

## Step 5: Update Index and Log

- Add `learning_plan.md` to `wiki/index.md` under a new `## Learning Resources` section (or append it if that section exists)
- Append to `wiki/log.md`:
```markdown
## [YYYY-MM-DD] learning_plan | Generated Learning Plan
- Created: wiki/learning_plan.md
- Tiers: X concepts across Y tiers
```

## Step 6: Build Website

After writing `learning_plan.md`, run the build script to regenerate the website with the learning plan included:

```bash
python3 ~/.claude/skills/wikify/scripts/build-site.sh wiki website
```

Run this from the wiki project root directory. The learning plan will appear as a "Learning Plan" link in the site nav, linking directly to its page.

## Step 7: Confirm

Report: "Learning plan created at `wiki/learning_plan.md` with X pages across Y tiers. Website rebuilt at `website/`." Offer to regenerate if the user wants different tier groupings.
