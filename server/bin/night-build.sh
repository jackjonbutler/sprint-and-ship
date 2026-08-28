#!/usr/bin/env bash
# Overnight build loop: one fresh agent invocation per manifest ticket.
source "$(dirname "$0")/lib.sh"
sync_repos
event night-build loop-start
FAILS=0; BUILT=0; ASKED=0
for i in $(seq 1 "${MAX_TICKETS_PER_NIGHT:-6}"); do
  # Each iteration is a FRESH context executing exactly one ticket (the ss-next procedure).
  if run_agent "night-build-$i" /work/prompts/night-ticket.md; then
    # agent exits with a final line we parse from transcript: NEXT | EMPTY | ASKED | FAILED
    last=$(tail -5 "$LOGDIR/runs/$(date +%F)-night-build-$i/transcript.txt" | grep -oE 'RESULT:(NEXT|EMPTY|ASKED|FAILED)' | tail -1 || true)
    case "$last" in
      RESULT:EMPTY) break ;;
      RESULT:ASKED) ASKED=$((ASKED+1)) ;;
      RESULT:NEXT)  BUILT=$((BUILT+1)); FAILS=0 ;;
      *)            FAILS=$((FAILS+1)) ;;
    esac
  else
    FAILS=$((FAILS+1))
  fi
  [ "$FAILS" -ge 2 ] && { tg "🔴 <b>Night build stopped</b> — two consecutive failures. Check logs."; break; }
done
event night-build loop-end "\"built\":$BUILT,\"asked\":$ASKED"
tg "🌅 <b>Night build done</b> — $BUILT PR(s) ready for review, $ASKED question(s) waiting. Morning review time."
