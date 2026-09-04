#!/usr/bin/env bash
# Plans a whole sprint by running the sprint-triage agent once per dependency wave,
# each in a FRESH context, until nothing is left to plan.
#
# Why a loop of fresh contexts rather than one long run: tickets in a wave must be
# planned aware of each other, but a wave planned before the previous one's schema
# decisions exist is planned against guesses. One wave per context keeps plans
# coherent; this loop just removes the need to send `plan` again by hand each time.
#
# Stops on: RESULT:DONE, RESULT:ASKED (a human is needed), two consecutive failures,
# or MAX_PLAN_WAVES as a runaway guard.
source "$(dirname "$0")/lib.sh"
sync_repos

event plan-sprint loop-start
FAILS=0; WAVES=0
i=0
while [ "$i" -lt "${MAX_PLAN_WAVES:-12}" ]; do
  i=$((i+1))
  run_agent "sprint-triage-$i" /work/prompts/sprint-triage.md; rc=$?
  if [ "$rc" -eq 2 ]; then
    MINS=$(( $(schedule_resume sas-triage) / 60 ))
    event plan-sprint paused '"reason":"session limit"'
    tg "⏸ <b>Planning paused — model session limit reached</b>%0A%0APlanned $WAVES wave(s) so far. I'll continue automatically in about ${MINS} minutes. No action needed."
    status_note "⏸ planning paused — session limit, auto-resume in ~${MINS}m"
    break
  fi
  if [ "$rc" -eq 0 ]; then
    last=$(grep -ohE 'RESULT:(MORE|DONE|ASKED|FAILED)' "$LOGDIR/runs/latest/transcript.txt" 2>/dev/null | tail -1 || true)
    case "$last" in
      RESULT:DONE)
        WAVES=$((WAVES+1))
        event plan-sprint done "\"waves\":$WAVES"
        tg "🗂 <b>Sprint fully planned</b> — $WAVES wave(s). Review the plans and set tickets to Plan Approved when you're happy."
        break ;;
      RESULT:MORE)   WAVES=$((WAVES+1)); FAILS=0 ;;
      RESULT:ASKED)
        WAVES=$((WAVES+1))
        event plan-sprint asked "\"waves\":$WAVES"
        tg "⏸ <b>Planning paused after wave $WAVES</b> — a ticket is Blocked and needs your answer. Reply, then send <b>plan</b> to continue."
        break ;;
      *)
        # No marker, or FAILED. An unmarked run is a failure: it means the agent died
        # or ignored the contract, and continuing would plan on top of an unknown state.
        FAILS=$((FAILS+1)) ;;
    esac
  else
    FAILS=$((FAILS+1))
  fi
  [ "$FAILS" -ge 2 ] && { tg "🔴 <b>Sprint planning stopped</b> — two consecutive failures after $WAVES wave(s). Check the logs."; break; }
done

[ "$i" -ge "${MAX_PLAN_WAVES:-12}" ] && tg "⚠️ <b>Sprint planning hit the wave limit</b> (${MAX_PLAN_WAVES:-12}) after $WAVES wave(s) — stopping as a safety guard. Send <b>plan</b> to continue if that was legitimate."
event plan-sprint loop-end "\"waves\":$WAVES"
status_note "🗂 sprint planning finished — $WAVES wave(s)"
