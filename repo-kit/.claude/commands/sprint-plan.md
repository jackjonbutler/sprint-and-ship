---
description: Order the Current sprint and write the execution manifest (lean orchestrator - no code reading)
allowed-tools: Read, mcp__notion__*, AskUserQuestion
---

# /sprint-plan — set up the sprint for fresh-context execution

You are a LEAN ORCHESTRATOR. Stay under ~15% context: do NOT read code, do NOT read full plans — only ticket titles, priorities, estimates, and plan Approach summaries.

1. Fetch the sprint with `Sprint status` = "Current" from the sprints database (`collection://{{SPRINTS_DB_COLLECTION_ID}}`) and its related tickets filtered to `Repo` = REPO_NAME.
2. Classify: ready (`AI Stage` = "Plan Approved") vs not ready (state why: Needs Plan / Plan Ready awaiting approval / Blocked).
3. Propose an execution order for ready tickets: High priority first → dependency order (skim plan Approaches for mentions of other tickets' outputs) → smallest estimate first. Confirm the order with the user via AskUserQuestion.
4. Write the manifest into the SPRINT PAGE BODY (replace any previous one):

   ## Execution Order (REPO_NAME)
   *Written by /sprint-plan on <date>. /next executes the first unchecked ticket.*
   - [ ] TKT-<id> — <title> (est: S/M/L)
   - [ ] TKT-<id> — <title> (est: M)
   ...
   ### Completed
   (empty — /next appends one-line summaries here)

5. STOP. Do not execute anything. End with exactly this instruction to the user:
   "Manifest written. Now: /clear, then /next — repeat until the sprint is empty. Each ticket runs in a fresh context."
