#!/usr/bin/env bash
# Overnight build loop: one fresh agent invocation per manifest ticket.
source "$(dirname "$0")/lib.sh"
sync_repos
event night-build loop-start
FAILS=0; BUILT=0; ASKED=0
# Land whatever is already reviewed-and-green first, so tonight's branches
# start from an up-to-date base instead of stacking on unmerged work.
[ -n "${MERGE_TRAIN_REPO:-}" ] && bin/merge-train.sh "$MERGE_TRAIN_REPO" "${MERGE_TRAIN_BASE:-development}" || true

for i in $(seq 1 "${MAX_TICKETS_PER_NIGHT:-6}"); do
  # Each iteration is a FRESH context executing exactly one ticket (the ss-next procedure).
  if run_agent "night-build-$i" /work/prompts/night-ticket.md; then
    # agent exits with a final line we parse from transcript: NEXT | EMPTY | ASKED | FAILED
    last=$(grep -ohE 'RESULT:(NEXT|EMPTY|ASKED|FAILED)' "$LOGDIR/runs/latest/transcript.txt" 2>/dev/null | tail -1 || true)
    case "$last" in
      RESULT:EMPTY) break ;;
      RESULT:ASKED) ASKED=$((ASKED+1)) ;;
      RESULT:NEXT)
        BUILT=$((BUILT+1)); FAILS=0
        # Land it NOW so the next ticket branches off a development that contains it.
        # Dependency-ordered manifests need this: otherwise ticket N+1 skips as "waiting".
        [ -n "${MERGE_TRAIN_REPO:-}" ] && bin/merge-train.sh "$MERGE_TRAIN_REPO" "${MERGE_TRAIN_BASE:-development}" || true
        ;;
      *)            FAILS=$((FAILS+1)) ;;
    esac
  else
    FAILS=$((FAILS+1))
  fi
  [ "$FAILS" -ge 2 ] && { tg "🔴 <b>Night build stopped</b> — two consecutive failures. Check logs."; break; }
done
# Land tonight's work too, so tomorrow starts clean.
[ -n "${MERGE_TRAIN_REPO:-}" ] && bin/merge-train.sh "$MERGE_TRAIN_REPO" "${MERGE_TRAIN_BASE:-development}" || true

event night-build loop-end "\"built\":$BUILT,\"asked\":$ASKED"
tg "🌅 <b>Night build done</b> — $BUILT PR(s) ready for review, $ASKED question(s) waiting. Morning review time."
