# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- `wiki/excluded.md` — tracks items noticed during Ingest but not compiled into dedicated pages, so nothing is silently lost; Query offers an on-demand raw-source read when a question touches an excluded item, with the time/token/quality tradeoff stated up front
- Large/mixed corpus re-confirmation checkpoint in Init — warns when categories are proposed from a small sample of a 100+ file corpus and offers to sample more broadly
- "Changing Categories Later" guidance documenting the delete-and-reinit recovery path for category schema changes
- Batch-fix mode for unambiguous missing cross-references in Lint, with per-category chunking for Missing Cross-References and Stub Detection checks on wikis over 50 pages (matching existing Contradictions chunking)
- Contradiction-lineage tracing in Lint — flags other pages (including Query-saved answer pages) that may repeat a claim after it's corrected
- Stub Detection stopword guard and user confirmation before stub page creation
- Two-pass shortlist fallback and RLM-style hierarchical synthesis in Query for wikis exceeding ~15 and ~200 relevant pages, respectively
- Optional hybrid-search guidance in Query for large wikis (non-default, no new dependency)
- PDF ingestion MCP dependency now documented in the skill and README, with a fallback path if unavailable
- Tightened `/wikify` query-routing trigger to require an explicit question or domain reference, reducing false-positive routing on ordinary conversation

- Project scaffolding and implementation plan
- README with full documentation
- MIT License
- `/wikify` global slash command with Init, Ingest, Query, and Lint workflows
- `scripts/build-site.sh` — static site generator with D3.js force graph
  - Interactive knowledge graph with 5-tier node sizing by inbound link frequency
  - Edge thickness scaled by connection strength (shared sources)
  - Right-click side panel for previewing wiki entries
  - Category pages with D3 bubble charts and source timeline
  - Individual page HTML with related page links
- Shell-based test suite (150 tests across 10 test files)
