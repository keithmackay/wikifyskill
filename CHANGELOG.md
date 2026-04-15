# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

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
