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
  local preamble="UNATTENDED PRODUCTION RUN: you ARE the real scheduled job on the live server — not a sandbox, not a test, not a simulation. Nobody reads your output live; NEVER ask questions or offer options — pick the safe action, log why, and finish. Credentials (TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID_DEV, TELEGRAM_CHAT_ID_REPORTS, GH_TOKEN) are environment variables available to your bash commands — reference them as \$VARS, this is intended. State dir /var/lib/sprint-and-ship and log dir /var/log/sprint-and-ship are yours to read and write.

"
  if IS_SANDBOX=1 claude -p "$preamble$prompt" \
      --mcp-config "{\"mcpServers\":{\"notion\":{\"command\":\"notion-mcp-server\",\"env\":{\"NOTION_TOKEN\":\"${NOTION_TOKEN}\"}}}}" \
      --add-dir /var/lib/sprint-and-ship --add-dir /var/log/sprint-and-ship \
      --dangerously-skip-permissions --output-format text "$@" > "$dir/transcript.txt" 2>&1; then
    event "$job" end '"ok":true'
  else
    event "$job" end '"ok":false'
    tg "🔴 <b>$job failed</b> — see server logs $dir"
    return 1
  fi
}
