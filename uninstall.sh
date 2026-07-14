#!/usr/bin/env bash
set -euo pipefail
DST="$HOME/.claude/skills"
for name in ss-sprint-plan ss-next ss-work ss-plan-ticket ss-ship ss-triage; do
  [ -e "$DST/$name" ] || [ -L "$DST/$name" ] && rm -rf "$DST/$name" && echo "removed: $name" || echo "not installed: $name"
done
