#!/usr/bin/env bash
# Shared helpers for all runners.
set -euo pipefail
LOGDIR=/var/log/sprint-and-ship
STATEDIR=/var/lib/sprint-and-ship
mkdir -p "$LOGDIR" "$STATEDIR" /work/repos

event() { # event <job> <type> <json-extra?>
  printf '{"ts":"%s","job":"%s","type":"%s"%s}\n' "$(date -Iseconds)" "$1" "$2" "${3:+,$3}" >> "$LOGDIR/events.jsonl"
}

tg() { # tg <text> [channel]  — channel: dev (default) | reports
  local chat="${TELEGRAM_CHAT_ID_DEV:-${TELEGRAM_CHAT_ID}}"
  [ "${2:-dev}" = "reports" ] && chat="${TELEGRAM_CHAT_ID_REPORTS:-$chat}"
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="$chat" -d parse_mode=HTML --data-urlencode text="$1" > /dev/null || true
}

sync_repos() { # clone/refresh every repo listed in REPOS="name=url name=url"
  for pair in $REPOS; do
    name="${pair%%=*}"; url="${pair#*=}"
    # authenticate private-repo clones with GH_TOKEN (never interactive)
    if [ -n "${GH_TOKEN:-}" ]; then url="${url/https:\/\/github.com\//https://x-access-token:${GH_TOKEN}@github.com/}"; fi
    export GIT_TERMINAL_PROMPT=0
    if [ -d "/work/repos/$name/.git" ]; then git -C "/work/repos/$name" fetch --all --prune --quiet
    else git clone --quiet "$url" "/work/repos/$name"; fi
  done
}

run_agent() { # run_agent <job> <prompt-file-or-string> [extra claude args...]
  local job="$1"; shift; local prompt="$1"; shift
  local dir="$LOGDIR/runs/$(date +%F)-$job"; mkdir -p "$dir"
  event "$job" start
  [ -f "$prompt" ] && prompt="$(cat "$prompt")"
  if claude -p "$prompt" \
      --mcp-config "{\"mcpServers\":{\"notion\":{\"command\":\"notion-mcp-server\",\"env\":{\"NOTION_TOKEN\":\"${NOTION_TOKEN}\"}}}}" \
      --permission-mode acceptEdits --output-format text "$@" > "$dir/transcript.txt" 2>&1; then
    event "$job" end '"ok":true'
  else
    event "$job" end '"ok":false'
    tg "🔴 <b>$job failed</b> — see server logs $dir"
    return 1
  fi
}
