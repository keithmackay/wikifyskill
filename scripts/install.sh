#!/usr/bin/env bash
# ABOUTME: Installs wikify.md to the Claude Code global commands directory.
# ABOUTME: Override install location with WIKIFY_INSTALL_DIR env var.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/../src/wikify.md"
INSTALL_DIR="${WIKIFY_INSTALL_DIR:-$HOME/.claude/commands}"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "Error: src/wikify.md not found at $SOURCE_FILE"
  exit 1
fi

mkdir -p "$INSTALL_DIR"
cp "$SOURCE_FILE" "$INSTALL_DIR/wikify.md"
echo "Installed wikify.md to $INSTALL_DIR/wikify.md"
