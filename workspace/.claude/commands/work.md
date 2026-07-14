---
description: Implement one approved ticket end to end, routed to its repo (usage - /work TKT-123)
allowed-tools: Task, Read, Write, Edit, Grep, Glob, Bash, mcp__notion__*
---

# /work $ARGUMENTS

Run the /next procedure (steps 2-8, skipping the manifest steps) for exactly ticket $ARGUMENTS: find it in the tasks database (`collection://{{TASKS_DB_COLLECTION_ID}}`) by ID, route by its Repo property, enforce the same gates (Plan Approved, clean tree or worktree, branch off origin/DEFAULT_BRANCH), build per plan, qa-verifier + code-reviewer, PR to DEFAULT_BRANCH, update Notion at each transition. If it's in the Current sprint's manifest, update the manifest too. End with the PR URL and what the user should test.
