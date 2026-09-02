#!/usr/bin/env bash
# Runs ON THE HOST (not in a container). Executes the small set of jobs that
# genuinely need Docker, on behalf of agents that must never have the socket.
#
# Security model: agents cannot ask for arbitrary commands. They drop a JSON
# request naming ONE of a fixed set of job types with validated parameters;
# anything else is rejected and logged. The agent never supplies a shell string.
set -uo pipefail

QUEUE="${QUEUE_DIR:-/var/lib/docker/volumes/server_state/_data/host-jobs}"
REPOS_ROOT="${REPOS_ROOT:-/opt}"
ALLOWED_REPOS="roam"                      # repo dir names this runner will touch
mkdir -p "$QUEUE"
echo "host-runner: watching $QUEUE"

log() { printf '[%s] %s\n' "$(date -Is)" "$*"; }

# Telegram straight from the host (this runner is outside the agent container, so it
# has no lib.sh). Credentials come from the same private env file everything else uses.
[ -f /opt/sprint-and-ship-env/.env ] && { set -a; . /opt/sprint-and-ship-env/.env; set +a; }
tg_host() {
  [ -n "${TELEGRAM_BOT_TOKEN:-}" ] || return 0
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TELEGRAM_CHAT_ID_DEV:-${TELEGRAM_CHAT_ID:-}}" -d parse_mode=HTML \
    --data-urlencode text="$1" >/dev/null 2>&1 || true
}

# Disk watch. Container builds leak images and cache; left alone they fill the disk and
# surface as baffling "no space left on device" errors inside unrelated jobs. Check on a
# timer as well as after each job, so an idle-but-leaking server still gets cleaned.
DISK_WARN_GB="${DISK_WARN_GB:-6}"     # below this after reclaiming, tell Jack
DISK_RECLAIM_GB="${DISK_RECLAIM_GB:-10}"  # below this, reclaim
LAST_DISK_CHECK=0
DISK_ALERTED=0

disk_watch() {
  local now; now=$(date +%s)
  [ $((now - LAST_DISK_CHECK)) -lt 300 ] && return 0   # at most every 5 minutes
  LAST_DISK_CHECK=$now
  local free; free=$(free_gb); [ -n "$free" ] || return 0
  if [ "$free" -lt "$DISK_RECLAIM_GB" ]; then
    log "disk: ${free}G free — reclaiming"
    reclaim
    free=$(free_gb)
    log "disk: ${free}G free after reclaim"
    if [ "$free" -lt "$DISK_WARN_GB" ] && [ "$DISK_ALERTED" -eq 0 ]; then
      tg_host "⚠️ <b>Build server disk low</b> — ${free}G free after automatic cleanup. Docker cleanup can't recover any more; this needs a bigger disk or something deleted by hand. Builds will start failing when it reaches zero."
      DISK_ALERTED=1
    fi
  elif [ "$free" -gt $((DISK_WARN_GB * 2)) ]; then
    DISK_ALERTED=0    # recovered — re-arm so a future squeeze alerts again
  fi
}

finish() { # finish <id> <ok:true|false> <summary-file>
  local id="$1" ok="$2" out="$3"
  python3 - "$QUEUE/$id.result" "$ok" "$out" <<'PY'
import json,sys
path,ok,out=sys.argv[1],sys.argv[2],sys.argv[3]
log=open(out,encoding="utf8",errors="ignore").read()[-8000:] if out else ""
json.dump({"ok":ok=="true","log":log},open(path,"w"))
PY
  rm -f "$QUEUE/$id.request" "$out"
}

# Every smoke build retags roam-api:smoke, orphaning the previous image (~500MB) and
# growing the build cache. Unreclaimed, that filled a 38G disk in days and surfaced as
# a confusing "no space left on device" inside unrelated jobs. Reclaim after every run.
reclaim() {
  docker image prune -f >/dev/null 2>&1 || true
  docker builder prune -f --keep-storage 5GB >/dev/null 2>&1 || true
}

free_gb() { df -BG --output=avail / 2>/dev/null | tail -1 | tr -dc '0-9'; }

smoke_api() { # smoke_api <repo> <ref> <outfile>
  local repo="$1" ref="$2" out="$3" dir="$REPOS_ROOT/$1"
  {
    echo "== smoke-api: $repo @ $ref =="
    # Fail with a clear reason rather than letting the build die on ENOSPC halfway.
    local avail; avail=$(free_gb)
    if [ -n "$avail" ] && [ "$avail" -lt 8 ]; then
      echo "only ${avail}G free before build — reclaiming"; reclaim; avail=$(free_gb)
      echo "after reclaim: ${avail}G free"
    fi
    if [ -n "$avail" ] && [ "$avail" -lt 4 ]; then
      echo "DISK FULL: ${avail}G free after reclaim. This is a host problem, not a code problem —"
      echo "the build was not attempted. Free space on the build server and re-run."
      return 1
    fi
    cd "$dir" || { echo "no such repo dir"; return 1; }
    git fetch --quiet --all --prune || true
    git checkout --quiet --force "$ref" || { echo "cannot checkout $ref"; return 1; }
    git pull --quiet --ff-only 2>/dev/null || true
    echo "-- building image --"
    docker build -q -f apps/api/Dockerfile -t roam-api:smoke . || { echo "BUILD FAILED"; return 1; }
    echo "-- starting container --"
    docker rm -f roam-api-smoke >/dev/null 2>&1
    docker run -d --name roam-api-smoke --env-file /opt/roam-api/.env -p 127.0.0.1:8099:8080 roam-api:smoke >/dev/null \
      || { echo "CONTAINER FAILED TO START"; return 1; }
    for i in $(seq 1 30); do
      code=$(curl -s -o /dev/null -w '%{http_code}' -m 3 http://127.0.0.1:8099/health || true)
      [ "$code" = "200" ] && { echo "HEALTH OK (200) after ${i}s"; docker rm -f roam-api-smoke >/dev/null; return 0; }
      sleep 1
    done
    echo "HEALTH CHECK FAILED — last 40 log lines:"
    docker logs --tail 40 roam-api-smoke 2>&1
    docker rm -f roam-api-smoke >/dev/null 2>&1
    return 1
  } >> "$out" 2>&1
}

while :; do
  disk_watch
  shopt -s nullglob
  for req in "$QUEUE"/*.request; do
    id="$(basename "$req" .request)"
    out="$QUEUE/$id.out"; : > "$out"
    job=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('job',''))" "$req" 2>/dev/null)
    repo=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('repo',''))" "$req" 2>/dev/null)
    ref=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('ref',''))" "$req" 2>/dev/null)

    # `reclaim` takes no repo/ref, so it is handled before those checks. It is still an
    # allowlisted job name — the agent cannot ask for an arbitrary command here either.
    if [ "$job" = "reclaim" ]; then
      log "RUN $id reclaim ($(free_gb)G free)"
      { echo "before: $(free_gb)G free"; reclaim; echo "after: $(free_gb)G free"; } >> "$out" 2>&1
      finish "$id" true "$out"; log "OK $id reclaim; $(free_gb)G free"; continue
    fi

    # validate: known job, allowlisted repo, git-safe ref
    if ! printf '%s' " $ALLOWED_REPOS " | grep -q " $repo "; then
      log "REJECT $id: repo '$repo' not allowed"; echo "rejected: repo not allowed" >> "$out"; finish "$id" false "$out"; continue
    fi
    if ! printf '%s' "$ref" | grep -qE '^[A-Za-z0-9._/-]{1,120}$'; then
      log "REJECT $id: unsafe ref"; echo "rejected: unsafe ref" >> "$out"; finish "$id" false "$out"; continue
    fi

    case "$job" in
      smoke-api)
        log "RUN $id smoke-api $repo@$ref"
        if smoke_api "$repo" "$ref" "$out"; then finish "$id" true "$out"; log "OK $id"
        else finish "$id" false "$out"; log "FAIL $id"; fi
        reclaim; log "reclaimed; $(free_gb)G free" ;;
      *)
        log "REJECT $id: unknown job '$job'"; echo "rejected: unknown job" >> "$out"; finish "$id" false "$out" ;;
    esac
  done
  sleep 5
done
