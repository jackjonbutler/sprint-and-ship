---
name: ss-plan-ticket
description: "Research and plan one ticket in its repo via researcher + planner subagents. Never writes application code."
argument-hint: "<TKT-id>"
---

<!-- Part of Sprint and Ship. Requires: workspace CLAUDE.md with the repo map (see workspace/ in the repo), Notion MCP, gh CLI. -->


# /plan-ticket $ARGUMENTS

Plan exactly one ticket. No application code.

1. Fetch $ARGUMENTS from the tasks database (`collection://{{TASKS_DB_COLLECTION_ID}}`); route by `Repo` to its folder; set `AI Stage` = "Researching". Read prior comments (address the user's plan feedback explicitly).
2. `researcher` subagent in that repo (it reads ARCHITECTURE/SYSTEM/GLOSSARY first).
3. `planner` subagent with ticket + findings. BLOCKED → AI Stage = "Blocked" + comment with its questions.
4. Else write the plan (planner's structure, incl. "### Success metric") into the ticket body, replacing any previous plan; set `AI Stage` = "Plan Ready".
