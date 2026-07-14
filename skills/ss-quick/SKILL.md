---
name: ss-quick
description: "Fast lane for small tasks: same guarantees (branch, atomic commits, tests, review, records) but skips the ticket→plan→approval ceremony. Refuses tasks that turn out to be big."
argument-hint: "<task description> [--research] [--validate]"
---

<!-- derived from gsd-quick (gsd-build/get-shit-done via mike-kirby-dev/dev-stack), MIT — reworked for Notion state instead of GSD's .planning/ tree. See ATTRIBUTIONS.md + licenses/gsd-LICENSE -->

# ss-quick — small task, full guardrails, no ceremony

For the two-line fix, typo, config bump, small copy change. NOT for features. The pipeline's plan-approval gate is skipped — everything else holds.

## Boundaries (check FIRST, and re-check while working)
Refuse and convert instead if the task: touches auth, payments/entitlements, data migrations, or deletion of user data; needs changes in more than ~3 files; turns out to need design decisions; or spans repos. Converting = create a ticket in the tasks database (`collection://{{TASKS_DB_COLLECTION_ID}}`) with AI Stage = "Needs Plan", tell the user it'll be planned tonight, stop.

## Flags
- `--research`: run the `researcher` subagent first (unsure where the change lives)
- `--validate`: also run `qa-verifier` before review (want executed evidence)
- Default path skips both; `code-reviewer` is NEVER skipped.

## Procedure
1. Identify the repo (workspace CLAUDE.md repo map); cd there. Clean tree or use a worktree off origin/DEFAULT_BRANCH.
2. Branch `quick/<slug>` off origin/DEFAULT_BRANCH.
3. Make the change. Atomic conventional commits. Run the repo's TEST_CMD + LINT_CMD.
4. (--validate) `qa-verifier`; always: `code-reviewer` on the diff. Fix blocking findings.
5. Push, `gh pr create` to DEFAULT_BRANCH — title `quick: <description>`, body: what/why/test evidence.
6. Record it (this is what keeps the fast lane honest):
   a. Create a ticket in the tasks database: title = the task, Status = "QA", body = 3-line summary + PR link. No AI Stage (it never entered the pipeline).
   b. Create a Changelog entry (`collection://{{CHANGELOG_DB_COLLECTION_ID}}`): Change, Ship date, Repo, Ticket relation, Success metric "none declared (quick)", Verdict "Too early", Release status "Merged".
7. Report: PR link + "review and ss-ship it like any ticket". The weekly report will show quick tasks alongside planned work — if quick tasks start dominating, that's a signal the backlog isn't capturing real work.
