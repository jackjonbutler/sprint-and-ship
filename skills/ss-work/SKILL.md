---
name: ss-work
description: "Implement one approved ticket end to end, routed to its repo. Refuses tickets not in Plan Approved."
argument-hint: "<TKT-id>"
---

<!-- Part of Sprint and Ship. Requires: workspace CLAUDE.md with the repo map (see workspace/ in the repo), Notion MCP, gh CLI. -->


# /work $ARGUMENTS

Run the /next procedure (steps 2-8, skipping the manifest steps) for exactly ticket $ARGUMENTS: find it in the tasks database (`collection://{{TASKS_DB_COLLECTION_ID}}`) by ID, route by its Repo property, enforce the same gates (Plan Approved, clean tree or worktree, branch off origin/DEFAULT_BRANCH), build per plan, qa-verifier + code-reviewer, PR to DEFAULT_BRANCH, update Notion at each transition. If it's in the Current sprint's manifest, update the manifest too. End with the PR URL and what the user should test.

## Sprint notes (working memory between tickets)
The repo root may contain `SPRINT-NOTES.md` — short, dated, cross-ticket facts left by earlier tickets in this sprint.
- **Read it immediately after ARCHITECTURE.md**, before designing your approach. It is deliberately small; reading it costs almost nothing and saves rediscovering things the hard way.
- **Append to it before you open your PR** IF this ticket learned something a *later ticket* would otherwise trip over: a surprise, a non-obvious command, a convention you had to settle, a path that moved. One or two lines, newest at top, prefixed with your ticket key. Include it in the same commit as your code.
- Do NOT append: ticket-specific detail (that belongs in your plan), a summary of what you built (the manifest and Changelog cover that), or process complaints (those go to the Improvement Log via the cycle review).
- If what you learned is a durable architectural fact, put it in ARCHITECTURE.md instead and skip the note.
- If the file does not exist and you have something worth recording, create it with the same rules at the top.
