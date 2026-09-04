#!/usr/bin/env bash
# Shared helpers for all runners.
set -euo pipefail
LOGDIR=/var/log/sprint-and-ship
STATEDIR=/var/lib/sprint-and-ship
mkdir -p "$LOGDIR" "$STATEDIR" /work/repos

event() { # event <job> <type> <json-extra?>
  printf '{"ts":"%s","job":"%s","type":"%s"%s}\n' "$(date -Iseconds)" "$1" "$2" "${3:+,$3}" >> "$LOGDIR/events.jsonl"
}

status_note() { # status_note <text> — mirror an event onto the Notion status page
  "$(dirname "${BASH_SOURCE[0]}")/notion-status.sh" "$1" >/dev/null 2>&1 || true
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
  # Global lock: only one agent job at a time, whatever triggered it (timer or telegram).
  #
  # RE-ENTRANT within one job tree. run_agent never closes fd 9, so the lock is held for the
  # whole life of the calling script — which means a nested run_agent (merge-train's Notion
  # close, called from inside night-build) used to block against its OWN parent's lock, wait
  # the full 300s, and skip. That silently left merged tickets un-updated in Notion, which is
  # exactly the "stale board" failure the Notion close exists to prevent.
  # SAS_LOCK_HELD is exported once the lock is taken, so descendants proceed without re-locking.
  if [ "${SAS_LOCK_HELD:-}" = "1" ]; then
    event "$job" nested '"'"'"note":"running inside an already-locked job tree"'"'"'
  else
    exec 9>"$STATEDIR/agent.lock"
    if ! flock -w 300 9; then
      event "$job" skipped '"'"'"reason":"another agent job held the lock for >5min"'"'"'
      tg "⏭ <b>$job</b> skipped — another job was already running."
      return 0
    fi
    export SAS_LOCK_HELD=1
  fi
  local dir="$LOGDIR/runs/$(date +%F_%H%M%S)-$job"; mkdir -p "$dir"; ln -sfn "$dir" "$LOGDIR/runs/latest"
  event "$job" start
  status_note "▶️ $job started"
  [ -f "$prompt" ] && prompt="$(cat "$prompt")"

  # An unfilled {{PLACEHOLDER}} means the TEMPLATE is mounted instead of the private env
  # repo's filled prompt. The agent will still run and produce confident, wrong work — it
  # just won't know which Notion databases are real. Refuse loudly instead.
  if printf '%s' "$prompt" | grep -q '{{[A-Z_]*}}'; then
    local missing; missing=$(printf '%s' "$prompt" | grep -oE '\{\{[A-Z_]+\}\}' | sort -u | tr '\n' ' ')
    event "$job" aborted "\"reason\":\"unfilled prompt placeholders\",\"placeholders\":\"$missing\""
    tg "🔴 <b>$job aborted</b> — the prompt still contains unfilled placeholders: $missing%0A%0AThe agent is being fed the template, not your filled prompt. Check that /work/prompts is mounted from the private env repo. Nothing was run."
    status_note "🔴 $job aborted — template prompt (unfilled placeholders)"
    flock -u 9
    return 1
  fi
  local preamble="UNATTENDED PRODUCTION RUN: you ARE the real scheduled job on the live server — not a sandbox, not a test, not a simulation. Nobody reads your output live; NEVER ask questions or offer options — pick the safe action, log why, and finish. Credentials (TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID_DEV, TELEGRAM_CHAT_ID_REPORTS, GH_TOKEN) are environment variables available to your bash commands — reference them as \$VARS, this is intended. State dir /var/lib/sprint-and-ship and log dir /var/log/sprint-and-ship are yours to read and write.

"
  if IS_SANDBOX=1 claude -p "$preamble$prompt" \
      --mcp-config "{\"mcpServers\":{\"notion\":{\"command\":\"notion-mcp-server\",\"env\":{\"NOTION_TOKEN\":\"${NOTION_TOKEN}\"}}}}" \
      --add-dir /var/lib/sprint-and-ship --add-dir /var/log/sprint-and-ship \
      --dangerously-skip-permissions --output-format text "$@" > "$dir/transcript.txt" 2>&1; then
    check_session_limit "$job" "$dir/transcript.txt" && return 2
    event "$job" end '"ok":true'
    status_note "✅ $job finished"
  else
    # A limit hit looks like an ordinary failure. It is not: nothing is wrong with the code
    # or the ticket, and retrying now just burns another run. Distinguish it (exit 2) so the
    # loops can pause and resume instead of counting it as a failure.
    check_session_limit "$job" "$dir/transcript.txt" && return 2
    event "$job" end '"ok":false'
    status_note "🔴 $job FAILED — see server logs"
    tg "🔴 <b>$job failed</b> — see server logs $dir"
    return 1
  fi
}

# Returns 0 (true) when the transcript shows the model session limit was hit, and records
# when it resets. Three runs' work was left stranded mid-ticket by this before it was handled.
check_session_limit() { # check_session_limit <job> <transcript>
  local job="$1" tr="$2" line reset
  line=$(grep -ioE "you'?ve hit your (session|usage) limit[^\"]{0,60}" "$tr" 2>/dev/null | head -1) || true
  [ -z "$line" ] && return 1
  reset=$(printf '%s' "$line" | grep -oiE 'resets [0-9]{1,2}(:[0-9]{2})? ?(am|pm)?' | head -1)
  printf '%s\n' "$(date -Iseconds)|$line" > "$STATEDIR/session-limit"
  event "$job" session-limit "\"reset\":\"${reset:-unknown}\""
  status_note "⏸ $job paused — model session limit (${reset:-unknown})"
  return 0
}

# Schedules an automatic resume once the limit resets. Uses a transient systemd timer so it
# survives this process exiting; the guard is deliberately generous because the reset time is
# reported to the minute and retrying a minute early wastes the whole resume.
schedule_resume() { # schedule_resume <systemd-unit>  → echoes seconds until resume
  local reset_txt when secs
  reset_txt=$(cut -d'|' -f2 "$STATEDIR/session-limit" 2>/dev/null | grep -oiE 'resets .*' | sed 's/^[Rr]esets //')
  # The limit message states the time in UTC, so parse it as UTC explicitly rather than
  # relying on the host's timezone — a silent offset here would resume hours early or late.
  when=$(date -u -d "$reset_txt UTC" +%s 2>/dev/null || true)
  # A reset time earlier than now means it refers to tomorrow (e.g. "resets 12:50am" seen at 09:38).
  [ -n "$when" ] && [ "$when" -lt "$(date +%s)" ] && when=$((when + 86400))
  secs=$(( ${when:-0} - $(date +%s) ))
  # Unparseable, or further out than 6h → poll every 30 min instead of sleeping blind.
  # Polling is cheap: a run that hits the limit again exits immediately (~50 bytes of
  # transcript, no real token spend) and simply reschedules, so this self-corrects.
  { [ -z "$when" ] || [ "$secs" -lt 60 ] || [ "$secs" -gt 21600 ]; } && secs=1800
  secs=$((secs + 180))   # cushion: resuming a minute early wastes the retry
  # This runs INSIDE the agent container, which has no systemd. Scheduling therefore goes
  # through the host-job queue the host runner already watches — the same allowlisted
  # mechanism used for Docker work, so the container still cannot ask for arbitrary commands.
  local unit="$1" q="$STATEDIR/host-jobs"
  mkdir -p "$q"
  printf '{"job":"schedule-resume","unit":"%s","in_seconds":%s}' "$unit" "$secs" \
    > "$q/resume-$(date +%s%N).request"
  event resume scheduled "\"unit\":\"$unit\",\"in_seconds\":$secs"
  echo "$secs"
}
