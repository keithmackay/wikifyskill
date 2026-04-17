#!/usr/bin/env bash
# ABOUTME: Removes the wikify command and skill from the Claude Code global directories.
# ABOUTME: Override install locations with WIKIFY_COMMANDS_DIR or WIKIFY_SKILLS_DIR env vars.

set -e

COMMANDS_DIR="${WIKIFY_COMMANDS_DIR:-$HOME/.claude/commands}"
SKILLS_DIR="${WIKIFY_SKILLS_DIR:-$HOME/.claude/skills/wikify}"

# Remove command
TARGET_FILE="$COMMANDS_DIR/wikify.md"
if [ -f "$TARGET_FILE" ]; then
  rm "$TARGET_FILE"
  echo "Removed $TARGET_FILE"
else
  echo "Command not found at $TARGET_FILE (already removed)"
fi

# Remove skill
if [ -d "$SKILLS_DIR" ]; then
  rm -rf "$SKILLS_DIR"
  echo "Removed $SKILLS_DIR"
else
  echo "Skill not found at $SKILLS_DIR (already removed)"
fi
