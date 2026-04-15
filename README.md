# wikifyskill

## Description

A Claude Code global slash command that implements Andrej Karpathy's LLM Wiki pattern. When invoked via `/wikify` in any project directory, it auto-detects context and runs the appropriate workflow:

- **Init** — Creates a 3-layer folder structure (`raw/`, `wiki/`, `WIKI_SCHEMA.md`) for building an LLM-maintained knowledge base
- **Ingest** — Processes new source files from `raw/` one at a time, with human discussion, creating cross-referenced Obsidian-compatible wiki pages
- **Query** — Synthesizes answers from the compiled wiki with citations back to source material
- **Lint** — Runs health checks for contradictions, orphan pages, stale claims, missing cross-references, and stub detection

The core insight: LLMs should *compile* knowledge into a persistent, structured wiki rather than re-derive answers via RAG on every query. The human curates sources and asks questions; the LLM handles all the bookkeeping — cross-references, consistency, contradiction detection — at near-zero marginal cost.

Supports all source file types: markdown, PDFs, images (via vision), code repositories, and structured data files.

## Highlights

- **Zero dependencies** — A single markdown file; no npm packages, no server, no database
- **Auto-detection** — `/wikify` figures out what to do based on folder state; no subcommands to remember
- **Obsidian-compatible** — All wiki pages use standard markdown with YAML frontmatter, viewable in Obsidian's graph view
- **Human-in-the-loop** — Ingest processes one source at a time, pausing for your context and direction
- **Compiled knowledge** — Cross-references, contradiction detection, and confidence tracking built into every page
- **Full lint suite** — Six automated health checks catch orphans, stale claims, broken links, and more

## Getting Started

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and configured
- Git (for version control of your wiki)

### Installation

```bash
git clone https://github.com/keithmackay/wikifyskill.git
cd wikifyskill
./scripts/install.sh
```

This copies `wikify.md` to `~/.claude/commands/`, making `/wikify` available in every project.

### Uninstall

```bash
./scripts/uninstall.sh
```

## Usage

### Initialize a new wiki

Navigate to any project directory and run:

```
/wikify
```

When no `raw/` or `wiki/` folder exists, wikifyskill creates the full folder structure:

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
│   ├── concepts/
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
1. Reads the source and presents key takeaways
2. Asks for your context or direction
3. Creates/updates wiki pages with full cross-references
4. Updates the index and processing log

### Query the wiki

```
/wikify what's the relationship between X and Y?
```

Synthesizes an answer from your compiled wiki with inline citations. Flags knowledge gaps and suggests sources to fill them.

### Run a health check

```
/wikify lint
```

Checks for contradictions, orphan pages, stale claims, missing cross-references, stub concepts, and broken links. Offers to fix issues one at a time.

### Supported file types

| Type | Extensions | Method |
|------|-----------|--------|
| Markdown/text | `.md`, `.txt`, `.html` | Direct read |
| PDF | `.pdf` | PDF MCP tool |
| Images | `.png`, `.jpg`, `.svg`, `.webp` | Vision |
| Code | `.py`, `.js`, `.ts`, `.rs`, etc. | Direct read |
| Data | `.csv`, `.json`, `.yaml` | Direct read |

## Build Static Website

Generate a browsable static site from your wiki with an interactive D3.js knowledge graph:

```bash
./scripts/build-site.sh
```

This creates a `website/` folder with:
- **Landing page** — Full-screen D3 force-directed graph with all wiki pages as nodes
- **Right-click panel** — Right-click any node to preview the wiki entry in a slide-out panel
- **Category pages** — Dedicated pages for Concepts, Entities, Sources, and Comparisons with D3 bubble charts and timelines
- **Individual pages** — HTML version of each wiki entry with related page links

Node sizes are scaled across 5 tiers based on how frequently a page is referenced (inbound link count). Edge thickness reflects connection strength (number of shared sources between connected pages).

Optionally specify custom paths: `./scripts/build-site.sh wiki/ output/`

## Development

```bash
git clone https://github.com/keithmackay/wikifyskill.git
cd wikifyskill
./tests/run_tests.sh
```

Tests are shell scripts using grep-based assertions to verify the skill file contains correct instructions. Run a single test with:

```bash
./tests/run_tests.sh tests/test_skill_file.sh
```

## Contributing

Contributions are welcome. Fork the repo, create a branch, and open a PR. All changes should include corresponding test updates in `tests/`.

## License

[MIT](LICENSE)
