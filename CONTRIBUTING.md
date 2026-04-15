# Contributing to wikifyskill

Thanks for your interest in contributing! Here's how to get started.

## Reporting Bugs

Open a [bug report](../../issues/new?template=bug_report.yml) with:
- What you expected to happen
- What actually happened
- Steps to reproduce
- Your Claude Code version

## Suggesting Features

Open a [feature request](../../issues/new?template=feature_request.yml) describing:
- The problem you're trying to solve
- Your proposed solution
- Alternatives you've considered

## Development Setup

```bash
git clone https://github.com/keithmackay/wikifyskill.git
cd wikifyskill
./tests/run_tests.sh
```

Tests are shell scripts with grep-based assertions. Run a single test:

```bash
./tests/run_tests.sh tests/test_skill_file.sh
```

The main skill file is `src/wikify.md`. After changes, reinstall with `./scripts/install.sh`.

## Pull Request Process

1. Fork the repo and create a feature branch
2. Write or update tests in `tests/` for your changes
3. Run `./tests/run_tests.sh` and confirm all tests pass
4. Open a PR with a clear description of what changed and why

## Code Style

- Shell scripts must start with a 2-line `# ABOUTME:` comment
- Use `set -e` in shell scripts
- Markdown skill content should use clear, imperative instructions
