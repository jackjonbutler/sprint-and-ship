---
description: Implement one approved ticket end to end (usage - /work TT-123)
allowed-tools: Task, Read, Write, Edit, Grep, Glob, Bash, mcp__notion__*
---

# /work $ARGUMENTS — implement a ticket

## Preflight (hard gates — stop if any fail)
1. Fetch ticket $ARGUMENTS from "Tasks - Tech" (`collection://{{TASKS_DB_COLLECTION_ID}}`).
2. Verify `AI Stage` = "Plan Approved" and `Repo` = REPO_NAME. If not, stop and explain.
3. `git status` is clean, and DEFAULT_BRANCH is up to date (`git checkout <DEFAULT_BRANCH> && git pull`).

## Setup
4. Create branch `feat/tt-<id>-<kebab-slug>` (or fix/ / chore/ based on ticket Tags).
5. Update Notion: `AI Stage` = "Building", `Status` = "In progress", `Branch` = the branch name.

## Build
6. Read "## Implementation Plan" from the ticket page. Execute it step by step.
7. Work in small commits — one plan step or logical unit per commit, conventional format, TT-<id> in the body.
8. Write/update tests as specified in the plan's test plan. Run TEST_CMD and LINT_CMD after each significant change, not just at the end.
9. If the plan turns out to be wrong or incomplete: make the smallest sensible adjustment, then update the plan section in Notion with a "### Deviations" note. If the deviation is large (different approach, new dependency, schema change), stop, set `AI Stage` = "Blocked", comment on the ticket, and wait for Jack.

## Verify (mandatory, in this order)
10. Launch `qa-verifier` subagent: it checks every acceptance criterion against the actual code and test results, and ticks the checkboxes in the Notion plan for criteria that pass.
11. Launch `code-reviewer` subagent on the full diff (`git diff <DEFAULT_BRANCH>...HEAD`). Fix everything it flags as blocking; re-run tests.

## Ship the PR
12. Push the branch. Create the PR with `gh pr create`:
    - Title: `TT-<id>: <ticket title>`
    - Body: link to the Notion ticket, summary of changes, test plan, any deviations from plan.
13. Update Notion: `AI Stage` = "PR Open", `Status` = "QA". Add a comment on the ticket with the PR URL and preview-deploy URL if available.
14. Report: what was built, what to look at in the preview, anything Jack should test by hand.
