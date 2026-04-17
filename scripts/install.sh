#!/usr/bin/env bash
# ABOUTME: Installs the wikify command and skill to the Claude Code global directories.
# ABOUTME: Override install locations with WIKIFY_COMMANDS_DIR or WIKIFY_SKILLS_DIR env vars.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/../src"

COMMANDS_DIR="${WIKIFY_COMMANDS_DIR:-$HOME/.claude/commands}"
SKILLS_DIR="${WIKIFY_SKILLS_DIR:-$HOME/.claude/skills/wikify}"

# Install command
if [ ! -f "$SRC_DIR/wikify.md" ]; then
  echo "Error: src/wikify.md not found at $SRC_DIR/wikify.md"
  exit 1
fi

mkdir -p "$COMMANDS_DIR"
cp "$SRC_DIR/wikify.md" "$COMMANDS_DIR/wikify.md"
echo "Installed command to $COMMANDS_DIR/wikify.md"

# Install skill
if [ ! -d "$SRC_DIR/skill" ]; then
  echo "Error: src/skill/ not found at $SRC_DIR/skill"
  exit 1
fi

mkdir -p "$SKILLS_DIR"
cp -r "$SRC_DIR/skill/." "$SKILLS_DIR/"
echo "Installed skill to $SKILLS_DIR/"
