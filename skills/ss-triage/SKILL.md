---
name: ss-triage
description: "Research and plan every Needs Plan ticket across all repos (interactive version of the nightly scheduled run). Never writes application code."
---

<!-- Part of Sprint and Ship. Requires: workspace CLAUDE.md with the repo map, Notion MCP. -->

# ss-triage — plan all new tickets, all repos

1. Query the tasks database (`collection://{{TASKS_DB_COLLECTION_ID}}` — see workspace CLAUDE.md) for tickets where `AI Stage` = "Needs Plan" (empty does not qualify) and Status is in the to-do group. None → say so, stop.
2. For each, oldest first: run the ss-plan-ticket procedure (route by Repo, researcher subagent, planner subagent, write plan incl. "### Success metric", set Plan Ready or Blocked-with-questions).
3. Finish with one line per ticket: "TKT-<id> — Plan Ready | Blocked (reason)". Never set Plan Approved; never change Status or Sprint.
