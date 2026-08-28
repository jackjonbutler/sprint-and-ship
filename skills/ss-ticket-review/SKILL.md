---
name: ss-ticket-review
description: "Post-build review agent: after a ticket's PR opens, assess how the dev cycle performed on it (plan accuracy, execution friction, gate effectiveness), store the data, and log improvement observations. Feeds sprint-close's self-improvement synthesis."
argument-hint: "<TKT-id>"
---

# ss-ticket-review — how did the CYCLE do on this ticket?

Not a code review (code-reviewer did that). This reviews the PROCESS. Runs automatically at the end of every ss-next / night-build ticket, after the PR opens.

## Gather the evidence
The ticket + its plan (including Deviations notes), the PR diff stats, the qa-verifier and code-reviewer findings from this run, test results, how many attempts/blockers occurred, whether questions were asked, timing.

## Assess (score each honestly: good / adequate / poor + one line why)
1. **Plan accuracy** — did the plan's Approach survive contact with the code? Count deviations and their size. Did it name the right files?
2. **Research quality** — did execution discover things research should have found (hidden coupling, missing patterns)?
3. **Scope discipline** — did the diff stay inside the plan's Out of scope fence?
4. **Gate value** — did qa-verifier or code-reviewer catch anything real, or rubber-stamp?
5. **Friction** — what cost the most time/tokens? (failed test loops, missing context, tool issues, unclear conventions)
6. **Sprint coherence** — if in a sprint: did the plan's "Depends on" assumptions about sibling tickets hold?

## Store
a. Write a "## Cycle review" section onto the ticket's Changelog entry (`collection://{{CHANGELOG_DB_COLLECTION_ID}}`) page body: the six assessments + stats (deviations, attempts, review findings count).
b. For each assessment that is "poor" — and any "adequate" with an obvious fix — create an entry in the Improvement Log (`collection://{{IMPROVEMENT_LOG_COLLECTION_ID}}`): Observation (specific, evidenced), Category, Ticket + Sprint relations, Proposed change (a concrete pipeline change: a prompt clause, a new gate, a docs addition, a threshold), Status "Noted", Source "ticket review".
Do NOT create duplicate observations — search the log first; if the same pattern exists, add a comment on it instead ("also hit on TKT-231"). Recurrence is signal.

## Rules
Never modify the plan, the code, or ticket status. Observations must cite evidence from THIS ticket. One ticket = max 3 observations — pick the ones that would change behavior, not a laundry list.
