---
name: ss-work
description: "Implement one approved ticket end to end, routed to its repo. Refuses tickets not in Plan Approved."
argument-hint: "<TT-id>"
---

<!-- Part of Sprint and Ship. Requires: workspace CLAUDE.md with the repo map (see workspace/ in the repo), Notion MCP, gh CLI. -->


# /work $ARGUMENTS

Run the /next procedure (steps 2-8, skipping the manifest steps) for exactly ticket $ARGUMENTS: find it in Tasks - Tech (`collection://{{TASKS_DB_COLLECTION_ID}}`) by ID, route by its Repo property, enforce the same gates (Plan Approved, clean tree or worktree, branch off origin/DEFAULT_BRANCH), build per plan, qa-verifier + code-reviewer, PR to DEFAULT_BRANCH, update Notion at each transition. If it's in the Current sprint's manifest, update the manifest too. End with the PR URL and what Jack should test.
