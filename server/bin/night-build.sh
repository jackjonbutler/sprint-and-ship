#!/usr/bin/env bash
# Overnight build loop: one fresh agent invocation per manifest ticket.
source "$(dirname "$0")/lib.sh"
sync_repos
event night-build loop-start
FAILS=0; BUILT=0; ASKED=0
# Land whatever is already reviewed-and-green first, so tonight's branches
# start from an up-to-date base instead of stacking on unmerged work.
[ -n "${MERGE_TRAIN_REPO:-}" ] && bin/merge-train.sh "$MERGE_TRAIN_REPO" "${MERGE_TRAIN_BASE:-development}" || true

# Unbounded by default: run until the manifest is exhausted (RESULT:EMPTY) or two
# consecutive failures. Set MAX_TICKETS_PER_NIGHT to re-impose a ceiling if ever needed.
i=0
while [ -z "${MAX_TICKETS_PER_NIGHT:-}" ] || [ "$i" -lt "$MAX_TICKETS_PER_NIGHT" ]; do
  i=$((i+1))
  # Each iteration is a FRESH context executing exactly one ticket (the ss-next procedure).
  run_agent "night-build-$i" /work/prompts/night-ticket.md; rc=$?
  if [ "$rc" -eq 2 ]; then
    # Model session limit. Not a failure — pause and come back when it resets, rather than
    # burning the remaining retries and leaving a half-built ticket stranded on its branch.
    MINS=$(( $(schedule_resume sas-build) / 60 ))
    event night-build paused '"reason":"session limit"'
    tg "⏸ <b>Build paused — model session limit reached</b>%0A%0ABuilt $BUILT ticket(s) before pausing. Any part-built ticket stays on its branch at AI Stage Building and will be <b>resumed, not restarted</b>.%0A%0AI'll pick it up automatically in about ${MINS} minutes. No action needed."
    status_note "⏸ build paused — session limit, auto-resume in ~${MINS}m"
    break
  fi
  if [ "$rc" -eq 0 ]; then
    # agent exits with a final line we parse from transcript: NEXT | EMPTY | ASKED | FAILED
    last=$(grep -ohE 'RESULT:(NEXT|EMPTY|ASKED|FAILED)' "$LOGDIR/runs/latest/transcript.txt" 2>/dev/null | tail -1 || true)
    # SAFETY NET: if the transcript says a ticket was blocked but the agent reported
    # success, the human never gets told. Catch it here rather than trusting the prompt.
    TR="$LOGDIR/runs/latest/transcript.txt"
    if [ "$last" = "RESULT:NEXT" ] && grep -qiE "set .*(AI Stage|stage).*(to )?.?Blocked|AI Stage *(=|:|->) *.?Blocked" "$TR" 2>/dev/null; then
      TICK=$(grep -ohE "TT-[0-9]+" "$TR" | tail -1)
      WHY=$(grep -ihE "blocked" "$TR" | grep -viE "^#" | tail -1 | cut -c1-320)
      tg "⚠️ <b>${TICK:-A ticket} was blocked but reported as complete</b> — you were not told, so here it is:%0A%0A$(printf '%s' "$WHY" | sed 's/[<>&]//g')%0A%0AOpen the ticket in Notion for the full reason. (This message came from the pipeline's safety net, not the agent — logged as a pipeline defect.)"
      event night-build notify-gap "\"ticket\":\"$TICK\""
      status_note "⚠️ ${TICK:-ticket} blocked but reported complete — safety net notified"
      last="RESULT:ASKED"
    fi
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
status_note "🌅 night build done — $BUILT built, $ASKED waiting on you"
tg "🌅 <b>Night build done</b> — $BUILT PR(s) ready for review, $ASKED question(s) waiting. Morning review time."
