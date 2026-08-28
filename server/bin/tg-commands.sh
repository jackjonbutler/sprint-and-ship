#!/usr/bin/env bash
# Telegram command listener — THE single consumer of getUpdates.
# Commands (from OWNER only): plan | build | status | help
# "TKT-<id>: answer" messages are appended to the inbox file for nightly-ops to process.
source "$(dirname "$0")/lib.sh"
OWNER="${TELEGRAM_OWNER_ID:?set TELEGRAM_OWNER_ID in .env}"
OFFSET_FILE="$STATEDIR/tg-offset"
INBOX="$STATEDIR/tg-inbox.jsonl"
LOCK="$STATEDIR/job.lock"
touch "$INBOX"

reply() { curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d chat_id="$1" -d parse_mode=HTML --data-urlencode text="$2" > /dev/null || true; }

run_locked() { # run_locked <chat> <label> <cmd...>
  local chat="$1" label="$2"; shift 2
  if ! flock -n 200; then reply "$chat" "⏳ A job is already running — try again when it finishes."; return; fi
  reply "$chat" "▶️ <b>$label</b> started..."
  if "$@" >> "$LOGDIR/tg-triggered.log" 2>&1; then reply "$chat" "✅ <b>$label</b> finished."
  else reply "$chat" "🔴 <b>$label</b> failed — check server logs."; fi
} 200>"$LOCK"

echo "tg-commands: listening"
while true; do
  OFF=$(cat "$OFFSET_FILE" 2>/dev/null || echo 0)
  RESP=$(curl -s --max-time 35 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?timeout=25&offset=$OFF") || { sleep 5; continue; }
  echo "$RESP" | jq -c '.result[]?' | while read -r upd; do
    UPDATE_ID=$(echo "$upd" | jq -r '.update_id')
    echo $((UPDATE_ID + 1)) > "$OFFSET_FILE"
    MSG=$(echo "$upd" | jq -r '.message.text // empty')
    FROM=$(echo "$upd" | jq -r '.message.from.id // empty')
    CHAT=$(echo "$upd" | jq -r '.message.chat.id // empty')
    [ -z "$MSG" ] && continue
    [ "$FROM" != "$OWNER" ] && continue   # only the owner commands the system
    CMD=$(echo "$MSG" | tr '[:upper:]' '[:lower:]' | xargs)
    case "$CMD" in
      plan|"run plan"|triage)  run_locked "$CHAT" "Sprint planning" bin/run-job.sh sprint-triage & ;;
      build|"run build")       run_locked "$CHAT" "Night build" bin/night-build.sh & ;;
      status)
        LAST=$(tail -3 "$LOGDIR/events.jsonl" 2>/dev/null | jq -r '"\(.ts | split("T")[1] | split("+")[0]) \(.job) \(.type)"' | paste -sd '; ' -)
        reply "$CHAT" "📟 last events: ${LAST:-none yet}" ;;
      help)
        reply "$CHAT" "Commands: <b>plan</b> (sprint planning now) · <b>build</b> (build loop now) · <b>status</b> · or answer questions as TKT-123: your answer" ;;
      tkt-*|TKT-*)
        echo "$upd" | jq -c '{ts: now | todate, from: .message.from.id, text: .message.text}' >> "$INBOX"
        reply "$CHAT" "📥 noted — will be applied to the ticket on the next ops run (or send: plan)" ;;
    esac
  done
done
