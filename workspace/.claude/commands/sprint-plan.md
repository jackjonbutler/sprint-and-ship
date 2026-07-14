---
description: Order the Current sprint across all repos and write the execution manifest (lean - no code reading)
allowed-tools: Read, mcp__notion__*, AskUserQuestion
---

# /sprint-plan — cross-repo sprint setup

You are a LEAN ORCHESTRATOR (~15% context max): read only ticket titles, Repo, priorities, estimates, and one-line plan summaries. No code.

1. Fetch the sprint with `Sprint status` = "Current" from Sprints - Tech (`collection://{{SPRINTS_DB_COLLECTION_ID}}`) and ALL its related tickets (every repo).
2. Classify: ready (`AI Stage` = "Plan Approved") vs not ready (say why).
3. Propose an execution order: High priority first → cross-ticket dependencies (backend endpoints before the frontend tickets that consume them — check plan summaries) → group same-repo tickets adjacently where it doesn't fight the above → smallest first. Confirm with Jack via AskUserQuestion.
4. Write into the SPRINT PAGE body (replace previous):

   ## Execution Order
   *Written by /sprint-plan on <date>. /next executes the first unchecked ticket in a fresh context.*
   - [ ] TT-<id> [backend] — <title> (est: M)
   - [ ] TT-<id> [frontend] — <title> (est: S)
   ...
   ### Completed
   (empty)

5. STOP. Do not execute. End with: "Manifest written — <n> tickets across <repos>. Now: /clear, then /next. Repeat until done. (Tip: /model opus before an L ticket's /next, /model sonnet otherwise.)"
