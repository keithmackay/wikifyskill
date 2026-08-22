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

## Flags

### `--dry-run`

If the user's message contains `--dry-run` (e.g. `wikify --dry-run`, or combined with a normal invocation like `wikify --dry-run` while `raw/` has new files), run Step 1 (Detect Context) as normal to determine which workflow applies, then run that workflow's full analysis, but stop before any file is created, modified, or deleted. Report what *would* happen instead.

This applies per routed workflow as follows:

- **Init** ([wikify-init.md](wikify-init.md)): run Steps 0 (category detection) normally. Instead of Step 1 (Create Directories) through Step 5 (Create wiki/overview.md), report the proposed category list and the full set of files/directories that would be created (`raw/`, `wiki/`, `WIKI_SCHEMA.md`, `wiki/index.md`, `wiki/log.md`, `wiki/overview.md`). Do not create anything.
- **Ingest** ([wikify-ingest.md](wikify-ingest.md)): run Steps 0-3 normally (read schema, discover unprocessed files, read sources, detect domain, present the summary of key takeaways and pages to create/update). Instead of Step 4 (Create and Update Wiki Pages) through Step 6 (Cross-Reference Pass), report the list of pages that would be created, the list of pages that would be updated (with a one-line reason each), and the `wiki/index.md` / `wiki/log.md` entries that would be added. Do not write any file.
- **Lint** ([wikify-lint.md](wikify-lint.md)): run all checks normally. If batch-fix mode would apply to any unambiguous missing cross-references, report what it would fix instead of applying the fix. The lint report itself is read-only already, so it is otherwise unaffected.
- **Learning Plan** ([wikify-learning-plan.md](wikify-learning-plan.md)): run Steps 1-3 normally (read concept pages, identify bedrock concepts, build the dependency graph). Instead of Step 4 (Write `wiki/learning_plan.md`) through Step 6 (Build Website), report the tier structure that would be written and note that `wiki/index.md` / `wiki/log.md` would be updated to reference it. Do not write any file or build the site.
- **Query**: unaffected — Query never writes without an explicit save offer in Step 6; if the user would be offered a save, note "Would offer to save this answer as a wiki page" instead of making the offer.

End with a summary headed **"## Dry Run — no changes were made"** listing every page/file that would be created or modified, grouped by path, instead of the workflow's normal completion report.

## Step 1: Detect Context

Examine the current working directory to determine which workflow to run. Use the Bash tool to check for the existence of directories and files.

**Check these conditions in order:**

1. **Help requested**: If the user's message contains `--help`, do not run any workflow. Instead, read and display the contents of `help.md` (in this skill's folder) verbatim, then stop.

1a. **Dry run requested**: If the user's message contains `--dry-run`, note this and continue detection as normal below to determine which workflow applies — see the `--dry-run` entry under **Flags** for how each workflow behaves in this mode.

2. **Version requested**: If the user's message contains `--version`, do not run any workflow. Instead: (a) read the installed version from `.claude-plugin/plugin.json` if present, else `.codex-plugin/plugin.json`, else `gemini-extension.json`, else (bare Claude Code install) the topmost version heading in `CHANGELOG.md`; (b) print `wikify v<installed-version>`; (c) best-effort update check — find this skill's GitHub source repo from `git remote get-url origin` if this is a git checkout on `github.com`, else the first `https://github.com/<owner>/<repo>` URL in `README.md`; if no repo is found or `gh` isn't installed/authenticated, stop here with no further output; (d) otherwise run `gh api repos/<owner>/<repo>/releases/latest -q .tag_name` (strip leading `v`) and append a status line: `Status: up to date` if equal, `Status: newer version available (v<latest>). To update: if you installed this via a Claude Code marketplace, run /plugin marketplace update <marketplace-name> then reinstall; otherwise, git pull in your install directory if it's a git checkout, or re-copy from https://github.com/<owner>/<repo> per this README's Installation section.` if installed is older, or `Status: ahead of latest release (development checkout)` if installed is newer; on any API failure, print nothing further. Then stop.

3. **Lint requested**: If the user's message contains the word "lint", read [wikify-lint.md](wikify-lint.md) and follow it exactly.

4. **Learning plan requested**: If the user's message contains "learning_plan" or "learning plan", read [wikify-learning-plan.md](wikify-learning-plan.md) and follow it exactly.

5. **Query requested**: If the user's message contains a question or search phrase (and it's not "lint" or "learning_plan"), read [wikify-query.md](wikify-query.md) and follow it exactly.

6. **Init needed**: If `WIKI_SCHEMA.md` does not exist in the current directory, read [wikify-init.md](wikify-init.md) and follow it exactly.

7. **Inconsistent state**: If only one of `raw/` or `wiki/` exists (but not both), warn the user: "Found [raw/|wiki/] but not [wiki/|raw/]. This looks like an incomplete setup. Would you like to run Init to fix this?" If yes, read [wikify-init.md](wikify-init.md) and follow it exactly.

8. **Ingest available**: If both `raw/` and `wiki/` exist, scan for unprocessed files (see Ingest Step 1 in [wikify-ingest.md](wikify-ingest.md)). If new files are found, read [wikify-ingest.md](wikify-ingest.md) and follow it exactly.

9. **Nothing to do**: If both directories exist and all files are processed, present this menu:
   - "All sources are processed. What would you like to do?"
   - **Query**: "Ask a question about the wiki"
   - **Lint**: "Run a health check"
   - **Add sources**: "Add new files to `raw/` and run wikify again"

**Workflow routing behavior:**

- **Init, Ingest, Lint, Learning Plan**: proceed directly. Announce in one line (e.g. "Detected: 3 unprocessed files. Starting Ingest."), then start.
- **Query**: proceed directly — no announcement needed, just answer.
- **Inconsistent state**: pause and ask the user before doing anything.
- **Nothing to do**: present the menu as described above.
