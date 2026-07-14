---
description: Merge, deploy and close a ticket (usage - /ship TT-123)
allowed-tools: Read, Bash, mcp__notion__*
---

# /ship $ARGUMENTS — merge & close

1. Fetch ticket $ARGUMENTS; find its PR (Branch property / `gh pr list --head <branch>`).
2. Gates: PR checks green (`gh pr checks`), no unresolved review threads, `AI Stage` = "PR Open". Stop and report if not.
3. Merge: `gh pr merge --squash --delete-branch`. Squash-commit title: `TT-<id>: <ticket title>`.
4. Verify deploy per CLAUDE.md DEPLOY config:
   - Vercel: wait for the production deployment of the merge commit, then hit the health/smoke URL.
   - Expo/EAS: trigger the configured build/update channel and report the build link.
5. If deploy fails: revert the merge (`gh pr revert` or `git revert`), set `AI Stage` = "Blocked", comment on the ticket with the failure, stop.
6. On success, update Notion: `Status` = "Done", clear `AI Stage`, add a closing comment: merge SHA, deploy URL/build link, one-line changelog entry.
7. `git checkout <DEFAULT_BRANCH> && git pull` so the workspace is ready for the next ticket.
