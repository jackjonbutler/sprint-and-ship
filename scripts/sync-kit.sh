#!/usr/bin/env bash
# Sync repo-kit/ into one of your repos (canonical-source flow).
# Usage: scripts/sync-kit.sh /path/to/your/repo
set -euo pipefail
REPO="${1:?usage: sync-kit.sh /path/to/repo}"
SRC="$(cd "$(dirname "$0")/../repo-kit" && pwd)"
cp -r "$SRC/.claude" "$REPO/"
echo "Synced .claude/ into $REPO — review 'git diff', keep your CLAUDE.md repo-config block, commit via PR."
echo "NOTE: CLAUDE.md not copied (repo-specific). Diff against $SRC/CLAUDE.md manually if the template changed."
