#!/usr/bin/env bash
# Called from INSIDE the agent container. Asks the host runner to perform a
# Docker-dependent job and waits for the result. Agents cannot run Docker
# themselves by design — this is the only route, and it accepts fixed job types.
#
# Usage: bin/request-host-job.sh smoke-api roam feat/tt-123-my-branch [timeout-seconds]
set -uo pipefail
JOB="${1:?job}"; REPO="${2:?repo}"; REF="${3:?ref}"; TIMEOUT="${4:-600}"
Q=/var/lib/sprint-and-ship/host-jobs
mkdir -p "$Q"
ID="$(date +%s)-$$"
printf '{"job":"%s","repo":"%s","ref":"%s"}' "$JOB" "$REPO" "$REF" > "$Q/$ID.request.tmp"
mv "$Q/$ID.request.tmp" "$Q/$ID.request"
echo "host-job $ID queued ($JOB $REPO@$REF), waiting up to ${TIMEOUT}s..."
for i in $(seq 1 "$TIMEOUT"); do
  if [ -f "$Q/$ID.result" ]; then
    python3 - "$Q/$ID.result" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
print("RESULT:", "PASS" if d.get("ok") else "FAIL")
print(d.get("log","")[-4000:])
PY
    ok=$(python3 -c "import json,sys;print('0' if json.load(open(sys.argv[1])).get('ok') else '1')" "$Q/$ID.result")
    rm -f "$Q/$ID.result"; exit "$ok"
  fi
  sleep 1
done
echo "RESULT: TIMEOUT — host runner did not answer in ${TIMEOUT}s (is sas-host-runner running?)"
exit 2
