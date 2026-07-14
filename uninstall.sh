#!/usr/bin/env bash
set -euo pipefail
DST="$HOME/.claude/skills"
for name in ss-sprint-plan ss-next ss-work ss-plan-ticket ss-ship ss-triage ss-quick sp-systematic-debugging sp-brainstorming gs-plan-eng-review; do
  if [ -e "$DST/$name" ] || [ -L "$DST/$name" ]; then rm -rf "$DST/$name"; echo "removed: $name"; else echo "not installed: $name"; fi
done
