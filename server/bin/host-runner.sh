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

smoke_api() { # smoke_api <repo> <ref> <outfile>
  local repo="$1" ref="$2" out="$3" dir="$REPOS_ROOT/$1"
  {
    echo "== smoke-api: $repo @ $ref =="
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
  shopt -s nullglob
  for req in "$QUEUE"/*.request; do
    id="$(basename "$req" .request)"
    out="$QUEUE/$id.out"; : > "$out"
    job=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('job',''))" "$req" 2>/dev/null)
    repo=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('repo',''))" "$req" 2>/dev/null)
    ref=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('ref',''))" "$req" 2>/dev/null)

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
        else finish "$id" false "$out"; log "FAIL $id"; fi ;;
      *)
        log "REJECT $id: unknown job '$job'"; echo "rejected: unknown job" >> "$out"; finish "$id" false "$out" ;;
    esac
  done
  sleep 5
done
