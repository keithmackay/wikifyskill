#!/usr/bin/env bash
# ABOUTME: Removes wikify.md from the Claude Code global commands directory.
# ABOUTME: Override install location with WIKIFY_INSTALL_DIR env var.

set -e

INSTALL_DIR="${WIKIFY_INSTALL_DIR:-$HOME/.claude/commands}"
TARGET_FILE="$INSTALL_DIR/wikify.md"

if [ -f "$TARGET_FILE" ]; then
  rm "$TARGET_FILE"
  echo "Removed $TARGET_FILE"
else
  echo "wikify.md not found at $TARGET_FILE (already removed)"
fi
