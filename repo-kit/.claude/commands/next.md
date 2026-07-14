---
description: Execute the next ticket in the Current sprint, fresh context, then stop (GSD-style)
allowed-tools: Task, Read, Write, Edit, Grep, Glob, Bash, mcp__notion__*
---

# /next — one ticket, full context, then hand back

You have a FRESH context dedicated to exactly one ticket. Do not look ahead at other tickets.

## Pick up the pointer
1. Fetch the "Current" sprint page from "Sprints - Tech" (`collection://{{SPRINTS_DB_COLLECTION_ID}}`). Read its "## Execution Order (REPO_NAME)" manifest.
2. The target = the FIRST unchecked ticket. If none remain: report the sprint complete, summarize the "### Completed" list, list anything sitting in QA awaiting /ship, and stop.
3. If the manifest is missing, say so and offer /sprint-plan. Never invent an order.

## Execute (the /work procedure, exactly)
4. Fetch the ticket. Hard gates: `AI Stage` = "Plan Approved", `Repo` = REPO_NAME, clean `git status`, DEFAULT_BRANCH up to date. Gate fails → mark the manifest line "⚠ skipped: <reason>", move it under Completed with that note, and stop (Jack decides).
5. Branch `feat/tt-<id>-<slug>` off DEFAULT_BRANCH. Notion: `AI Stage` = "Building", `Status` = "In progress", `Branch` set.
6. Read the ticket's "## Implementation Plan". Execute step by step; small conventional commits; run TEST_CMD + LINT_CMD as you go. Small deviations → note in plan; large → Blocked + comment + stop.
7. `qa-verifier` subagent on the acceptance criteria, then `code-reviewer` subagent on the full diff. Fix blocking findings; re-run tests.
8. Push; `gh pr create` (title `TT-<id>: <title>`, body links ticket + test plan). Notion: `AI Stage` = "PR Open", `Status` = "QA", comment with PR URL.

## Transition (GSD-style checkpoint)
9. Update the sprint manifest: check the ticket off and move its line to "### Completed" with a one-line summary: "TT-<id> — <what shipped> — PR <url>".
10. STOP. End with the completion protocol, exactly:
    "✅ TT-<id> done — PR: <url>
    Sprint: <n> of <total> complete. Next up: TT-<id2> — <title>.
    → /clear, then /next"
    (If that was the last one: "🏁 Sprint execution complete. Review the QA column, then /ship each ticket.")
