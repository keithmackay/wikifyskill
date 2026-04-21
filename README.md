# wikifyskill

![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)
![Last Commit](https://img.shields.io/github/last-commit/keithmackay/wikifyskill)

A Claude Code global slash command that implements Andrej Karpathy's LLM Wiki pattern. When invoked via `/wikify` in any project directory, it auto-detects context and runs the appropriate workflow:

- **Init** — Creates a layered folder structure (`raw/`, `wiki/`, `WIKI_SCHEMA.md`) with domain-aware categories proposed from your source material
- **Ingest** — Processes new source files from `raw/` one at a time, with human discussion, creating cross-referenced wiki pages
- **Query** — Synthesizes answers from the compiled wiki with citations back to source material
- **Lint** — Runs health checks for contradictions, orphan pages, stale claims, missing cross-references, and stub detection
- **Learning Plan** — Generates a dependency-ordered reading guide across all wiki pages, organized into tiers from bedrock concepts to advanced topics

The core insight: LLMs should *compile* knowledge into a persistent, structured wiki rather than re-derive answers via RAG on every query. The human curates sources and asks questions; the LLM handles all the bookkeeping — cross-references, consistency, contradiction detection — at near-zero marginal cost.

Supports all source file types: markdown, PDFs, images (via vision), code repositories, and structured data files.

## Table of Contents

- [Highlights](#highlights)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Build Static Website](#build-static-website)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Highlights

- **Zero dependencies** — A single markdown file and a Python script; no npm packages, no server, no database
- **Auto-detection** — `/wikify` figures out what to do based on folder state; no subcommands to remember
- **Domain-aware init** — Scans your source material and proposes category structures tailored to your domain (fiction, research, technical, business, etc.)
- **Obsidian-compatible** — All wiki pages use standard markdown with YAML frontmatter, viewable in Obsidian's graph view
- **Human-in-the-loop** — Ingest processes one source at a time, pausing for your context and direction
- **Compiled knowledge** — Cross-references, contradiction detection, and confidence tracking built into every page
- **Full lint suite** — Six automated health checks catch orphans, stale claims, broken links, and more
- **Static site generator** — Ships with a Python script that builds a browsable D3.js knowledge graph site from any wiki

## Getting Started

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and configured
- Python 3 (for the static site generator)
- Git (for version control of your wiki)

### Installation

```bash
git clone https://github.com/keithmackay/wikifyskill.git
cd wikifyskill
./scripts/install.sh
```

This copies:
- `src/wikify.md` → `~/.claude/commands/wikify.md` (the `/wikify` slash command)
- `src/skill/` → `~/.claude/skills/wikify/` (the autonomous skill + `build-site.sh`)

To install to a custom location:

```bash
WIKIFY_INSTALL_DIR=~/.config/claude/commands ./scripts/install.sh
```

### Uninstall

```bash
./scripts/uninstall.sh
```

## Installation

### Claude Code

```bash
git clone https://github.com/keithmackay/wikifyskill.git
cd wikifyskill
./scripts/install.sh
```

This installs both the `/wikify` slash command and the autonomous skill. Invoke with `/wikify`.

Or install the skill only:

```bash
cp -r src/skill/ ~/.claude/skills/wikify/
```

### Codex

Add the plugin to your marketplace config:

**`~/.agents/plugins/marketplace.json`** (create if absent):
```json
{
  "name": "personal",
  "interface": { "displayName": "Personal Plugins" },
  "plugins": [
    {
      "name": "wikify",
      "source": { "source": "local", "path": "/path/to/wikifyskill/src/skill/" },
      "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
      "category": "Productivity"
    }
  ]
}
```

### Antigravity

The root `src/skill/SKILL.md` is natively compatible with Antigravity (no platform-specific metadata to strip).

**Global install** (all workspaces):
```bash
cp -r src/skill/ ~/.gemini/antigravity/skills/wikify/
```

**Workspace install** (current project only):
```bash
cp -r src/skill/ .agents/skills/wikify/
```

### Gemini CLI

Gemini CLI installs extensions directly from GitHub:

```bash
gemini extensions install https://github.com/keithmackay/wikifyskill
```

To update:
```bash
gemini extensions update wikify
```

The skill is auto-discovered from `GEMINI.md` after installation. Note: the repository must be publicly accessible on GitHub for `gemini extensions install` to work.

## Compatibility

| Feature | Claude Code | Codex | Antigravity | Gemini CLI |
|---------|:-----------:|:-----:|:-----------:|:----------:|
| Core skill (Init, Ingest, Query, Lint, Learning Plan) | ✅ | ✅ | ✅ | ✅ |
| Sub-documents (`wikify-init.md`, etc.) | ✅ | ✅ | ✅ | ✅ |
| Scripts (`scripts/build-site.sh`) | ✅ | ✅ | ✅ | ✅ |
| `/wikify` slash command | ✅ | ❌ | ❌ | ❌ |

Legend: ✅ Supported · ❌ Not supported

> **Note on the slash command:** The `/wikify` slash command is a Claude Code-specific convenience that mirrors the skill. On Codex, Antigravity, and Gemini CLI, invoke the skill by name (e.g., "run wikify" or mention `/wikify`).

## References

- **Claude Code Skills:** https://code.claude.com/docs/en/skills
- **Claude Code Complete Guide (PDF):** https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf
- **Codex Plugins:** https://developers.openai.com/codex/plugins/build
- **Antigravity Skills:** https://antigravity.google/docs/skills
- **Gemini CLI Extensions:** https://github.com/google-gemini/gemini-cli/blob/main/docs/extension.md
- **Agent Skills open standard:** https://agentskills.io/home

## Usage

### Initialize a new wiki

Navigate to any project directory and run:

```
/wikify
```

When no `raw/` or `wiki/` folder exists, wikifyskill scans for existing files in `raw/` and proposes domain-appropriate categories. For a fiction corpus it might suggest `characters`, `locations`, `factions`; for a technical corpus, `concepts`, `tools`, `apis`. Confirm or provide your own list, and the full folder structure is created:

```
project-root/
├── raw/                    # Layer 1: Your source material (read-only)
│   ├── articles/
│   ├── papers/
│   ├── repos/
│   ├── data/
│   ├── images/
│   └── assets/
├── wiki/                   # Layer 2: LLM-maintained knowledge base
│   ├── index.md            # Content catalog
│   ├── log.md              # Processing history
│   ├── overview.md         # High-level summary
│   ├── concepts/           # (or your chosen categories)
│   ├── entities/
│   ├── sources/
│   └── comparisons/
└── WIKI_SCHEMA.md          # Layer 3: Schema and conventions
```

### Ingest sources

Drop files into `raw/` (articles, PDFs, images, code, data files) and run:

```
/wikify
```

The skill detects unprocessed files and walks you through each one:
1. Reads the source and presents key takeaways, identified entities, and identified concepts
2. Asks for your context or direction before writing anything
3. Creates or updates wiki pages with full cross-references
4. Updates the index and processing log

### Query the wiki

```
/wikify what's the relationship between X and Y?
```

Synthesizes an answer from your compiled wiki with inline citations. Flags knowledge gaps and suggests sources to fill them. Offers to save the answer as a new wiki page.

### Run a health check

```
/wikify lint
```

Runs six checks and presents a summary table:

| Check | What it catches |
|-------|----------------|
| Contradictions | Conflicting claims across pages |
| Orphan pages | Pages with zero inbound links |
| Stale claims | Raw files modified after their summary was written |
| Missing cross-references | One-directional links that should be bidirectional |
| Stub detection | Terms mentioned in 2+ pages but lacking their own page |
| Broken links | References to files that no longer exist |

### Generate a learning plan

```
/wikify learning_plan
```

Reads all wiki pages and produces `wiki/learning_plan.md` — a dependency-ordered reading guide organized into tiers from bedrock concepts to advanced and integrative topics. Rebuilds the static site automatically if one exists.

### Supported file types

| Type | Extensions | Method |
|------|-----------|--------|
| Markdown/text | `.md`, `.txt`, `.html` | Direct read |
| PDF | `.pdf` | PDF MCP tool |
| Images | `.png`, `.jpg`, `.svg`, `.webp` | Vision |
| Code | `.py`, `.js`, `.ts`, `.rs`, etc. | Direct read |
| Data | `.csv`, `.json`, `.yaml` | Direct read |
| Repositories | Directories in `raw/repos/` | README first, then key files |

## Build Static Website

Generate a browsable static site from your wiki with an interactive D3.js knowledge graph:

```bash
python3 ~/.claude/scripts/build-site.sh wiki website
```

Or directly from this repo before installing:

```bash
python3 src/skill/scripts/build-site.sh wiki website
```

This creates a `website/` folder with:
- **Landing page** — Full-screen D3 force-directed graph with all wiki pages as nodes
- **Right-click panel** — Right-click any node to preview the wiki entry in a slide-out panel without leaving the graph
- **Category pages** — Two-column layout with expandable list items and a D3 bubble chart or timeline visualization
- **Individual pages** — HTML version of each wiki entry with related page links

Node sizes scale across 7 tiers based on inbound link count. Edge thickness reflects connection strength (number of shared sources between connected pages). The site works when opened directly via `file://` with no server required.

## Development

```bash
git clone https://github.com/keithmackay/wikifyskill.git
cd wikifyskill
./tests/run_tests.sh
```

Tests are shell scripts using grep-based assertions to verify the skill file contains the correct instructions. Run a single test file:

```bash
./tests/run_tests.sh tests/test_skill_file.sh
```

The main skill file is `src/wikify.md`. After changes, reinstall with `./scripts/install.sh`.

See [docs/TESTING_GUIDELINES.md](docs/TESTING_GUIDELINES.md) for guidance on writing new tests.

## Contributing

Contributions are welcome — fork the repo, create a branch, and open a PR. See [CONTRIBUTING.md](CONTRIBUTING.md) for the full development workflow, PR process, and code style conventions.

## License

[MIT](LICENSE)
