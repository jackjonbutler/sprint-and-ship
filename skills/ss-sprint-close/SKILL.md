---
name: ss-sprint-close
description: "Close the Current sprint: full accounting, summary written to the sprint page, carryover handling, docs-drift check, retro. GSD complete-milestone analog."
---

# /sprint-close — close the book on the Current sprint

## 1. Account for everything
Fetch the "Current" sprint (`collection://{{SPRINTS_DB_COLLECTION_ID}}`) + its manifest + all related tickets. Classify each: SHIPPED (Done), IN QA (PR open, not shipped — ask the user: ship now via /ship, or carry over?), SKIPPED/BLOCKED (reason from manifest/ticket), NOT STARTED. A sprint can close with loose ends — but they must be explicit, not forgotten.

## 2. Write "## Sprint Summary" into the sprint page (below the manifest)
- **Stats**: N planned → N shipped / N carried / N dropped; estimate mix; quick tasks (ss-quick) that happened alongside
- **Shipped**: one line each — what it does now, PR link, release status (Live vs awaiting release — from Changelog `collection://{{CHANGELOG_DB_COLLECTION_ID}}`)
- **Carryover**: tickets + why they didn't land
- **Plan vs reality**: deviations recorded in ticket plans during the sprint — what the plans got wrong (this is how planning improves)
- **Docs freshness**: for each shipped ticket, check whether it should have touched ARCHITECTURE/SYSTEM/GLOSSARY (per golden rule "fix docs in same PR") and didn't — list suspected drift
- **Retro**: ask the user 3 questions via AskUserQuestion (what dragged? what surprised? change one thing next sprint?) and record the answers


## 2b. Improvement synthesis (the self-improving loop)
Fetch every Improvement Log entry (`collection://{{IMPROVEMENT_LOG_COLLECTION_ID}}`) with Status "Noted" from this sprint (and any still Noted from earlier sprints). Synthesize:
- Cluster recurring observations — three tickets hitting the same friction is one systemic issue, not three notes
- For each cluster worth acting on, draft a concrete pipeline change and create a ticket: Repo = "pipeline", AI Stage = "Needs Plan", Summary = the observation cluster + proposed change + links to the log entries. Mark those log entries "Scoped" with the ticket related.
- Reject noise explicitly: weak/one-off observations get Status "Rejected" with a one-line reason (an honest reject keeps the log trustworthy)
- Cap: max 3 pipeline tickets per sprint close — the pipeline must never crowd out product work. Put them in the user's hands like any ticket: they get planned by sprint-triage when dragged into a sprint, built by the night loop, and the system has improved itself through its own gates.
Add a "### Pipeline improvements" section to the Sprint Summary: what was scoped, what was rejected and why.

## 3. Transition (only after the user confirms the summary)
- Sprint status: Current → "Last" (Notion moves the old Last → Past automatically; if not, set it)
- Carryover tickets: move their Sprint relation to the next sprint if one exists, else clear it (back to backlog) — the user chooses per ticket or "all"
- If a "Next" sprint exists and the user says go: flip it to Current. Do NOT populate it — sprint assembly stays the user's job.

## 4. End with the state of the world
"Sprint <name> closed: <n> shipped (<n> live, <n> awaiting release), <n> carried. Docs drift: <list|none>. Next sprint: <name|not created>. When it's assembled: /sprint-plan."

