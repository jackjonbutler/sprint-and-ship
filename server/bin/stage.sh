#!/usr/bin/env bash
# Report the current ticket + stage so humans can see progress mid-run.
# Usage: bin/stage.sh TT-341 "code review"
# Writes to the event log AND the Notion status page the dashboard reads.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TICKET="${1:?ticket}"; STAGE="${2:?stage}"
mkdir -p /var/log/sprint-and-ship /var/lib/sprint-and-ship
printf '{"ts":"%s","job":"stage","ticket":"%s","stage":"%s"}\n' "$(date -Iseconds)" "$TICKET" "$STAGE" >> /var/log/sprint-and-ship/events.jsonl
printf '{"ticket":"%s","stage":"%s","ts":"%s"}' "$TICKET" "$STAGE" "$(date -Iseconds)" > /var/lib/sprint-and-ship/current-stage.json
"$DIR/notion-status.sh" "🔧 $TICKET ▸ $STAGE" >/dev/null 2>&1 || true
