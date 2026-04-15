# wikifyskill

## Description

A Claude Code global slash command that implements Andrej Karpathy's LLM Wiki pattern. When invoked via `/wikify` in any project directory, it auto-detects context and runs the appropriate workflow:

- **Init** — Creates a 3-layer folder structure (`raw/`, `wiki/`, `WIKI_SCHEMA.md`) for building an LLM-maintained knowledge base
- **Ingest** — Processes new source files from `raw/` one at a time, with human discussion, creating cross-referenced Obsidian-compatible wiki pages
- **Query** — Synthesizes answers from the compiled wiki with citations back to source material
- **Lint** — Runs health checks for contradictions, orphan pages, stale claims, missing cross-references, and stub detection

The core insight: LLMs should *compile* knowledge into a persistent, structured wiki rather than re-derive answers via RAG on every query. The human curates sources and asks questions; the LLM handles all the bookkeeping — cross-references, consistency, contradiction detection — at near-zero marginal cost.

Supports all source file types: markdown, PDFs, images (via vision), code repositories, and structured data files.

## Installation

*Coming soon*

## Usage

*Coming soon*

## License

*Coming soon*
