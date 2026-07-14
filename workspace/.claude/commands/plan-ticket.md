---
description: Research and plan one ticket in its repo (usage - /plan-ticket TT-123)
allowed-tools: Task, Read, Grep, Glob, Bash(git *), mcp__notion__*
---

# /plan-ticket $ARGUMENTS

Plan exactly one ticket. No application code.

1. Fetch $ARGUMENTS from Tasks - Tech (`collection://{{TASKS_DB_COLLECTION_ID}}`); route by `Repo` to its folder; set `AI Stage` = "Researching". Read prior comments (address Jack's plan feedback explicitly).
2. `researcher` subagent in that repo (it reads ARCHITECTURE/SYSTEM/GLOSSARY first).
3. `planner` subagent with ticket + findings. BLOCKED → AI Stage = "Blocked" + comment with its questions.
4. Else write the plan (planner's structure, incl. "### Success metric") into the ticket body, replacing any previous plan; set `AI Stage` = "Plan Ready".
