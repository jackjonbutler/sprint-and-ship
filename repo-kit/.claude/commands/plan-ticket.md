---
description: Research and plan a single ticket (usage - /plan-ticket TT-123)
allowed-tools: Task, Read, Grep, Glob, Bash(git *), mcp__notion__*
---

# /plan-ticket $ARGUMENTS

Run the /triage procedure (steps 2a–2f) for exactly one ticket: $ARGUMENTS.

Find it in "Tasks - Tech" (`collection://{{TASKS_DB_COLLECTION_ID}}`) by its `ID` property. Plan it regardless of its current `AI Stage` (this is also how a plan gets re-done after feedback — read any Notion comments Jack left on the previous plan and address them explicitly in the new plan).

Do not write application code. End by setting `AI Stage` = "Plan Ready" (or "Blocked" with a comment).
