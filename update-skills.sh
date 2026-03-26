#!/usr/bin/env bash
#
# update-skills.sh — Pull latest skills from the Communal Mind template
#
# Usage: ./update-skills.sh [template-repo-url]
#

set -euo pipefail

TEMPLATE_REPO="${1:-https://github.com/omegalens/communal-mind.git}"
TEMP_DIR=$(mktemp -d)
SKILLS_DIR=".claude/skills"

cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

echo "Fetching latest communal skills from template..."
echo ""

if ! git clone --depth 1 --quiet "$TEMPLATE_REPO" "$TEMP_DIR" 2>/dev/null; then
  echo "Error: Could not clone template repo."
  echo "Usage: ./update-skills.sh https://github.com/YOUR_ORG/communal-mind.git"
  exit 1
fi

SKILL_FILES=(commune.md mindscape.md)

CHANGES=0
CHANGED_FILES=()

for file in "${SKILL_FILES[@]}"; do
  local_file="$SKILLS_DIR/$file"
  template_file="$TEMP_DIR/$SKILLS_DIR/$file"

  if [ ! -f "$template_file" ]; then
    continue
  fi

  if [ ! -f "$local_file" ]; then
    echo "  + $file (new skill)"
    CHANGED_FILES+=("$file")
    CHANGES=$((CHANGES + 1))
  elif ! diff -q "$local_file" "$template_file" >/dev/null 2>&1; then
    echo "  ~ $file (changed)"
    CHANGES=$((CHANGES + 1))
    CHANGED_FILES+=("$file")
  else
    echo "  . $file (unchanged)"
  fi
done

echo ""

if [ $CHANGES -eq 0 ]; then
  echo "All skills are up to date."
  exit 0
fi

echo "$CHANGES skill(s) have updates available."
echo ""
read -p "Show diffs? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  for file in "${CHANGED_FILES[@]}"; do
    echo ""
    echo "--- $file ---"
    diff --color "$SKILLS_DIR/$file" "$TEMP_DIR/$SKILLS_DIR/$file" 2>/dev/null || true
  done
  echo ""
fi

read -p "Apply skill updates? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  for file in "${CHANGED_FILES[@]}"; do
    cp "$TEMP_DIR/$SKILLS_DIR/$file" "$SKILLS_DIR/$file"
    echo "  ✓ Updated $file"
  done
  echo ""
  echo "Skills updated."
else
  echo "No changes made."
  exit 0
fi

echo ""
if ! diff -q "CLAUDE.md" "$TEMP_DIR/CLAUDE.md" >/dev/null 2>&1; then
  read -p "CLAUDE.md also has changes. Update it? [y/N] " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    cp "$TEMP_DIR/CLAUDE.md" "CLAUDE.md"
    echo "  ✓ Updated CLAUDE.md"
  fi
fi

echo ""
echo "Done."
