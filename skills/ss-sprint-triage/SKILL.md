---
name: ss-sprint-triage
description: "Plan an entire sprint as one unit: research all tickets together, order by dependency, then plan each ticket WITH the other tickets' plans as context so plans never clash. Replaces per-ticket triage as the main planning path."
---

# ss-sprint-triage — plan the sprint holistically

The user specs tickets (title + rough description is enough) and drags them into a sprint. This skill plans them together. Individual-ticket triage (ss-plan-ticket) remains for urgent out-of-sprint work only.

## 1. Scope
Fetch the sprint page with Sprint status "Next" from the sprints data source (`collection://{{SPRINTS_DB_COLLECTION_ID}}`). That is the ONLY sprint this skill plans — the user stages upcoming work in Next; Current is executing and is never planned or re-planned.

**Get the ticket list from the sprint page's `Tasks` relation property — it is the authoritative list. Fetch those exact page IDs.** Do NOT discover tickets by searching the tasks database: search returns unrelated tickets and is the wrong source of truth here. If the sprint page has no Tasks relation entries, report that and stop rather than guessing.

**Read the sprint page body before planning anything.** The user often writes a sprint goal, dependency waves, prior-art pointers, risks, decisions taken, and a cut line there. That content overrides your own ordering instinct: if the body specifies waves or an order, follow it and say so; if it names source files to read (e.g. ports from another codebase), read them; if it flags a ticket as "returning Blocked is a correct outcome", honour that.

Plannable = AI Stage empty, "Needs Plan", or "Blocked"-with-answered-questions. Already-approved tickets are context, not targets — never rewrite an approved plan without flagging it. For large sprints (>15 plannable tickets), plan in the body's wave order and report progress per wave; it is fine for one run to plan the first waves and leave later ones for the next run — say clearly which tickets are planned and which remain.

## 2. Batch research (one pass per repo, not per ticket)
Group tickets by Repo. Per repo, run the `researcher` subagent ONCE with all that repo's tickets: relevant files per ticket, and crucially the OVERLAPS — files/models/endpoints touched by more than one ticket, and which tickets logically depend on which (an endpoint one ticket adds that another consumes). Read ARCHITECTURE.md/SYSTEM.md first; cross-repo dependencies come from SYSTEM.md's integration map.

## 3. Order first
Decide the execution order before writing any plan: hard dependencies first (producer before consumer, cross-repo: api before mobile), then shared-file tickets adjacent (so the second plans against the first's known output), then priority, then smallest. Write the "## Execution Order" manifest to the sprint page (the ss-next format), plus a "### Shared surfaces" section: each file/model touched by 2+ tickets and in which order they'll touch it.

## 4. Plan sequentially, each ticket knowing the others
Plan tickets IN MANIFEST ORDER. For ticket N, the `planner` subagent receives: the ticket, its research, the manifest, AND the plans of tickets 1..N-1. Rules that kill clashes:
- Plan against the future state: assume earlier tickets' changes exist ("builds on the `/periods` endpoint TKT-214 adds — do not re-create it")
- Name shared files consistently with earlier plans; if ticket N would restructure something ticket 2 just built, STOP and flag the conflict to the user instead of planning around it
- Explicitly state each plan's assumptions about sibling tickets under "### Depends on"
Each plan uses the standard structure (Goal / Context / Approach / Depends on / Out of scope / Acceptance criteria / Success metric / Test plan / Estimate & risk), written to the ticket body; AI Stage → "Plan Ready".
A ticket too vague to plan → Blocked + comment with questions + Telegram; keep planning the rest, noting the hole in the manifest.

## 5. Hand over
Sprint page gets a "### Planning summary": tickets planned, order rationale, shared surfaces, flagged conflicts, open questions. Telegram: "🗂 Sprint <name> planned — <n> tickets ordered, <m> questions. Review the plans, approve, and the night builds begin." The user reviews the batch and flips tickets to Plan Approved — the gate is unchanged.
