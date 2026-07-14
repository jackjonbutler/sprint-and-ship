---
name: ss-ship
description: "Merge a ticket's PR in its repo, update Notion, handle per-repo release semantics."
argument-hint: "<TKT-id>"
---

<!-- Part of Sprint and Ship. Requires: workspace CLAUDE.md with the repo map (see workspace/ in the repo), Notion MCP, gh CLI. -->


# /ship $ARGUMENTS

1. Fetch ticket $ARGUMENTS; route by `Repo`; cd into that repo folder. Find the PR (Branch property / `gh pr list --head`).
2. Gates: `AI Stage` = "PR Open"; `gh pr checks` green; no unresolved threads. Fail → report, stop.
3. `gh pr merge --squash --delete-branch`. Remember: this lands in DEFAULT_BRANCH (development for backend/frontend — NOT production; master for website = production via Vercel).
4. Post-merge by repo: website → wait for the Vercel production deployment, smoke-check the site; deploy failed → revert the merge, AI Stage = Blocked, comment, stop. backend/frontend → no deploy now; note in the closing comment that it ships with the next development → main release (the nightly run tracks it going Live).
5. Notion: `Status` = "Done", clear `AI Stage`, closing comment: merge SHA + release note. If the Current sprint manifest lists it, annotate its Completed line with "shipped".
6. If the user says to release: development → main promotion is ITS OWN deliberate action — confirm with the user explicitly before merging development into main, then verify per the repo's DEPLOY config (server platform picks up main; mobile CI build link).
