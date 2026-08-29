# Template — copy to private env repo. Resolves a rebase conflict for ONE pull request.
You are resolving a merge conflict so a ticket's PR can land. Repos are cloned at /work/repos/.

## Scope — narrow by design
1. Identify the PR under conflict (the merge train passes it; if ambiguous, take the oldest open PR whose title starts with a ticket key and whose `mergeable` is false).
2. In that repo: `git fetch origin`, check out the PR's head branch, `git rebase origin/<DEFAULT_BRANCH>`.
3. Resolve ONLY the conflicted hunks. You may not change behaviour, refactor, rename, or "improve" anything while you are in here. If a conflicted file needs a real design decision, STOP (see below).
4. Resolution principles, in order:
   - Both sides added independent entries (imports, exports, config keys, workspace members, migration files): keep BOTH, ordered as the file's existing convention dictates.
   - The base changed a line the branch also changed: prefer the base's version and re-apply the branch's *intent* on top — the base is already merged truth.
   - Lockfiles (`pnpm-lock.yaml` etc.): never hand-merge. Take the base's version, then regenerate (`pnpm install --lockfile-only`).
   - Generated files (types, build output): take the base and regenerate with the documented command.
   - Migration files: never renumber or rewrite an already-merged migration. If two migrations collide on a timestamp, rename only YOUR branch's file.
5. Run the repo's TEST_CMD and LINT_CMD. They must pass before you push.
6. `git push --force-with-lease` (never plain `--force`).
7. Comment on the PR summarising exactly which files conflicted and how each was resolved.


## The squashed-dependency case (common — solve it, do not stop)
Symptom: the branch was cut from another ticket's branch, that ticket was then **squash-merged** into the base, and now a plain `git rebase` replays commits whose content is already in the base — producing add/add, rename/delete or "already applied" conflicts on files you never touched.

Recognise it by: `git log --oneline origin/<BASE>..<branch>` showing commits belonging to *other* tickets (a different TT- number) that are already in the base as one squash commit.

Recipe:
1. Find the last commit on the branch that belongs to another ticket — call it `$LAST_FOREIGN`.
2. `git rebase --onto origin/<BASE> $LAST_FOREIGN <branch>` — replays ONLY this ticket's own commits onto the base, dropping the duplicated ones.
3. If that still conflicts, the branch genuinely depends on work that has not landed yet: STOP, and report which ticket must merge first. Do not invent the missing work.
4. Push with an explicit lease so it cannot clobber: `git push --force-with-lease=<branch>:<sha-you-fetched> <remote> HEAD:<branch>`. A bare `--force-with-lease` fails with "stale info" when pushing a differently-named local branch.

This is history surgery, but it is *mechanical* history surgery — no design decision is involved, so it does not qualify for the STOP rules. Only stop if step 3 applies, or if the dropped commits contain changes that are NOT in the base (verify with `git diff origin/<BASE> -- <paths>` before assuming).

## STOP conditions — park, do not guess
If resolving requires choosing between two genuinely different behaviours, if the base has moved the ground under the branch's whole approach, if tests fail after resolution and the fix isn't obviously part of the conflict, or if the conflict touches auth/payments/money math or a migration already applied to a shared database: abandon the rebase (`git rebase --abort`), leave the branch untouched, set the ticket's AI Stage to "Blocked", comment on both the PR and the ticket with the specific decision needed, and Telegram the DEV channel. A half-resolved conflict is worse than a parked one.

## Never
Merge the PR yourself (the merge train does that), touch any branch other than the PR's head, force-push without `--with-lease`, or resolve a conflict by deleting the other side's work.
