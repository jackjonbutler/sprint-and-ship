#!/usr/bin/env bash
# Symlinks skills/*/ into ~/.claude/skills/ (idempotent). --copy to copy instead
# of symlinking (Windows without developer mode). Conflicting non-symlink entries abort.
set -euo pipefail
MODE="${1:-link}"
SRC="$(cd "$(dirname "$0")/skills" && pwd)"
DST="$HOME/.claude/skills"
mkdir -p "$DST"
for skill in "$SRC"/*/; do
  name="$(basename "$skill")"
  target="$DST/$name"
  if [ -L "$target" ]; then echo "skip (already linked): $name"; continue; fi
  if [ -e "$target" ]; then
    if [ "$MODE" = "--copy" ]; then rm -rf "$target"; cp -r "$skill" "$target"; echo "copied (replaced): $name"; continue; fi
    echo "ABORT: $target exists and is not a symlink. Remove it or rerun with --copy." >&2; exit 1
  fi
  if [ "$MODE" = "--copy" ]; then cp -r "$skill" "$target"; echo "copied: $name"
  else ln -s "$skill" "$target"; echo "linked: $name"; fi
done
echo "Done. Skills available in every Claude Code session. Updates: git pull (symlinks auto-resolve; --copy installs need rerun)."
