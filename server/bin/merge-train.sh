#!/usr/bin/env bash
# Merge train: land eligible PRs into DEFAULT_BRANCH one at a time, oldest first,
# restacking each onto the updated base. Never touches PROD_BRANCH.
# Eligibility (ALL required): checks green, no unresolved review threads,
# not draft, has the pipeline label/title prefix, mergeable after rebase.
source "$(dirname "$0")/lib.sh"
REPO="${1:?usage: merge-train.sh <owner/repo> <default-branch>}"
BASE="${2:?}"
API="https://api.github.com/repos/$REPO"
gh_api() { curl -s -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json" "$@"; }

merged=0; parked=0
while :; do
  # oldest open PR whose title starts with a ticket key
  PR=$(gh_api "$API/pulls?state=open&sort=created&direction=asc&per_page=20" \
    | jq -r '[.[] | select(.draft==false) | select(.title|test("^TT-[0-9]+"))] | .[0] // empty')
  [ -z "$PR" ] && break
  NUM=$(echo "$PR" | jq -r .number); TITLE=$(echo "$PR" | jq -r .title)
  HEAD=$(echo "$PR" | jq -r .head.ref); CURBASE=$(echo "$PR" | jq -r .base.ref)

  # 1. retarget stacked PRs onto the real base
  if [ "$CURBASE" != "$BASE" ]; then
    gh_api -X PATCH "$API/pulls/$NUM" -d "{\"base\":\"$BASE\"}" > /dev/null
    event merge-train retargeted "\"pr\":$NUM,\"from\":\"$CURBASE\",\"to\":\"$BASE\""
    sleep 3
  fi

  # 2. refresh state, check mergeability + checks
  ST=$(gh_api "$API/pulls/$NUM")
  MERGEABLE=$(echo "$ST" | jq -r .mergeable)
  SHA=$(echo "$ST" | jq -r .head.sha)
  CHECKS=$(gh_api "$API/commits/$SHA/check-runs" | jq -r '[.check_runs[]? | select(.conclusion!="success" and .conclusion!="neutral" and .conclusion!=null)] | length')
  REVIEWS=$(gh_api "$API/pulls/$NUM/reviews" | jq -r '[.[] | select(.state=="CHANGES_REQUESTED")] | length')

  if [ "$CHECKS" != "0" ] || [ "$REVIEWS" != "0" ]; then
    event merge-train parked "\"pr\":$NUM,\"reason\":\"failing checks ($CHECKS) or changes requested ($REVIEWS)\""
    tg "⏸ <b>PR #$NUM</b> $TITLE — not merged: failing checks or changes requested."
    parked=$((parked+1)); break
  fi

  if [ "$MERGEABLE" = "false" ]; then
    # conflict: hand to an agent to rebase-resolve in a dedicated run
    event merge-train conflict "\"pr\":$NUM"
    tg "🧩 <b>PR #$NUM</b> $TITLE — merge conflict against $BASE. Running conflict resolution..."
    if run_agent "merge-conflict-$NUM" "/work/prompts/merge-conflict.md" 2>/dev/null; then
      sleep 5; MERGEABLE=$(gh_api "$API/pulls/$NUM" | jq -r .mergeable)
    fi
    if [ "$MERGEABLE" != "true" ]; then
      tg "🔴 <b>PR #$NUM</b> still conflicted after automated rebase — needs a human."
      parked=$((parked+1)); break
    fi
  fi

  # 3. squash merge
  RESP=$(gh_api -X PUT "$API/pulls/$NUM/merge" -d "{\"merge_method\":\"squash\",\"commit_title\":\"$TITLE (#$NUM)\"}")
  if echo "$RESP" | jq -e .merged >/dev/null 2>&1 && [ "$(echo "$RESP" | jq -r .merged)" = "true" ]; then
    gh_api -X DELETE "$API/git/refs/heads/$HEAD" > /dev/null
    event merge-train merged "\"pr\":$NUM,\"title\":\"$TITLE\""
    merged=$((merged+1))
  else
    event merge-train failed "\"pr\":$NUM,\"resp\":$(echo "$RESP" | jq -c .message)"
    tg "🔴 <b>PR #$NUM</b> merge call failed: $(echo "$RESP" | jq -r .message)"
    parked=$((parked+1)); break
  fi
  sleep 4
done

event merge-train done "\"merged\":$merged,\"parked\":$parked"
[ "$merged" -gt 0 ] && tg "🚂 <b>Merge train</b>: $merged PR(s) merged into $BASE$([ "$parked" -gt 0 ] && echo ", $parked parked")."
exit 0
