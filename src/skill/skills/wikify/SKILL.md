---
name: wikify
description: Build and maintain an LLM-compiled knowledge wiki (Karpathy pattern). Use when the user wants to build a wiki, ingest source files into a knowledge base, query a compiled wiki, run a wiki health check (lint), or generate a learning plan from a wiki. Also use when the user mentions "raw/" or "wiki/" directories in the context of knowledge management.
---

# wikify — LLM Knowledge Wiki

The wikify skill compiles source material into a persistent, cross-referenced knowledge base. The LLM handles all bookkeeping — page creation, cross-references, contradiction detection, confidence tracking — while the human curates sources and asks questions.

> **build-site.sh** is bundled at `~/.claude/skills/wikify/scripts/build-site.sh`. Run it from any wiki project root:
> ```bash
> python3 ~/.claude/skills/wikify/scripts/build-site.sh wiki website
> ```

## Step 1: Detect Context

Examine the current working directory to determine which workflow to run. Use the Bash tool to check for the existence of directories and files.

**Check these conditions in order:**

1. **Lint requested**: If the user's message contains the word "lint", read [wikify-lint.md](wikify-lint.md) and follow it exactly.

2. **Learning plan requested**: If the user's message contains "learning_plan" or "learning plan", read [wikify-learning-plan.md](wikify-learning-plan.md) and follow it exactly.

3. **Query requested**: If the user's message contains a question or search phrase (and it's not "lint" or "learning_plan"), read [wikify-query.md](wikify-query.md) and follow it exactly.

4. **Init needed**: If `WIKI_SCHEMA.md` does not exist in the current directory, read [wikify-init.md](wikify-init.md) and follow it exactly.

5. **Inconsistent state**: If only one of `raw/` or `wiki/` exists (but not both), warn the user: "Found [raw/|wiki/] but not [wiki/|raw/]. This looks like an incomplete setup. Would you like to run Init to fix this?" If yes, read [wikify-init.md](wikify-init.md) and follow it exactly.

6. **Ingest available**: If both `raw/` and `wiki/` exist, scan for unprocessed files (see Ingest Step 1 in [wikify-ingest.md](wikify-ingest.md)). If new files are found, read [wikify-ingest.md](wikify-ingest.md) and follow it exactly.

7. **Nothing to do**: If both directories exist and all files are processed, present this menu:
   - "All sources are processed. What would you like to do?"
   - **Query**: "Ask a question about the wiki"
   - **Lint**: "Run a health check"
   - **Add sources**: "Add new files to `raw/` and run wikify again"

**Workflow routing behavior:**

- **Init, Ingest, Lint, Learning Plan**: proceed directly. Announce in one line (e.g. "Detected: 3 unprocessed files. Starting Ingest."), then start.
- **Query**: proceed directly — no announcement needed, just answer.
- **Inconsistent state**: pause and ask the user before doing anything.
- **Nothing to do**: present the menu as described above.
