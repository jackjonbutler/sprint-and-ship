---
name: ss-next
description: "Execute the next sprint ticket in a fresh context, routed to its repo by the Notion Repo property, then stop (GSD-style). Run from the workspace root containing your repos."
---

<!-- Part of Sprint and Ship. Requires: workspace CLAUDE.md with the repo map (see workspace/ in the repo), Notion MCP, gh CLI. -->


# /next — one ticket, one repo, one fresh context

## Pick up the pointer
1. Fetch the "Current" sprint page (`collection://{{SPRINTS_DB_COLLECTION_ID}}`); read "## Execution Order". Target = FIRST unchecked ticket. None left → report sprint complete: summarize "### Completed", list tickets in QA awaiting /ship, stop. No manifest → offer /sprint-plan; never invent an order.
2. Fetch the target ticket. Its `Repo` property routes you: look up the matching folder, DEFAULT_BRANCH, TEST_CMD and LINT_CMD in the workspace CLAUDE.md repo map. ALL git/test/gh commands run inside that folder (`cd` first). Never run git at workspace root.

## Gates (fail → mark manifest line "⚠ skipped: <reason>", move under Completed, stop)
3. `AI Stage` = "Plan Approved". Repo folder's `git status` clean on a safe branch; `git fetch` and cut the ticket branch from origin/DEFAULT_BRANCH: `feat/tkt-<id>-<slug>` (fix/, chore/ per ticket Tags). NOTE: if the repo's working tree has the user's uncommitted in-flight work, use a worktree instead: `git worktree add ../<repo>-tt<id> -b feat/tkt-<id>-<slug> origin/DEFAULT_BRANCH` and build there; remove it after the PR is pushed.
4. Notion: `AI Stage` = "Building", `Status` = "In progress", `Branch` set.

## Build
5. Read the ticket's "## Implementation Plan"; read the repo's ARCHITECTURE.md (+ SYSTEM.md if the plan mentions another repo). Execute the plan step by step: small conventional commits referencing TKT-<id>, run that repo's TEST_CMD + LINT_CMD as you go. Small deviations → "### Deviations" note in the Notion plan; large → AI Stage = Blocked + comment + stop.
6. `qa-verifier` subagent on the acceptance criteria (tell it the repo folder + TEST_CMD), then `code-reviewer` subagent on `git diff origin/DEFAULT_BRANCH...HEAD`. Fix blocking findings; re-run tests.

## PR + transition
7. Push; `gh pr create` from inside the repo folder — PR targets DEFAULT_BRANCH (development for backend/frontend, master for website). Title `TKT-<id>: <title>`; body: Notion ticket link, summary, test plan, deviations.
8. Notion: `AI Stage` = "PR Open", `Status` = "QA", comment the PR URL.
9. Manifest: check the ticket off, move its line to "### Completed": "TKT-<id> [repo] — <one-line summary> — PR <url>".
10. STOP with exactly:
    "✅ TKT-<id> done — PR: <url>
    Sprint: <n>/<total>. Next up: TKT-<id2> [repo] — <title> (est: X).
    → /clear, then /next"
    (Last one: "🏁 Sprint execution complete. Review QA, /ship each ticket, then /sprint-close to write the summary and hand over.")

## Sprint notes (working memory between tickets)
The repo root may contain `SPRINT-NOTES.md` — short, dated, cross-ticket facts left by earlier tickets in this sprint.
- **Read it immediately after ARCHITECTURE.md**, before designing your approach. It is deliberately small; reading it costs almost nothing and saves rediscovering things the hard way.
- **Append to it before you open your PR** IF this ticket learned something a *later ticket* would otherwise trip over: a surprise, a non-obvious command, a convention you had to settle, a path that moved. One or two lines, newest at top, prefixed with your ticket key. Include it in the same commit as your code.
- Do NOT append: ticket-specific detail (that belongs in your plan), a summary of what you built (the manifest and Changelog cover that), or process complaints (those go to the Improvement Log via the cycle review).
- If what you learned is a durable architectural fact, put it in ARCHITECTURE.md instead and skip the note.
- If the file does not exist and you have something worth recording, create it with the same rules at the top.
