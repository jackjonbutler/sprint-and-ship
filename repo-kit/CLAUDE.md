# CLAUDE.md — Trips Together Dev Pipeline

This repo is part of the Trips Together one-man dev team system. Tickets live in Notion, code lives here, PRs go through GitHub.

## Repo config (edit per repo)

- REPO_NAME: brochure site  <!-- must match the "Repo" select in Notion Tasks - Tech: frontend | backend | brochure site -->
- DEFAULT_BRANCH: main
- TEST_CMD: npm test
- LINT_CMD: npm run lint
- BUILD_CMD: npm run build
- DEPLOY: Vercel auto-deploys `main`; PR branches get preview deploys.

## Notion (source of truth for work)

- Tickets: "Tasks - Tech" — data source `collection://{{TASKS_DB_COLLECTION_ID}}`
- Sprints: "Sprints - Tech" — data source `collection://{{SPRINTS_DB_COLLECTION_ID}}`
- Ticket key = the `ID` property (auto-increment). Refer to tickets as TT-<ID>.
- Pipeline property: `AI Stage` = Needs Plan → Researching → Plan Ready → Plan Approved → Building → PR Open (→ Blocked at any point).
- Workflow property: `Status` = Backlog → Not started → In progress → QA → Done.
- Only work tickets where `Repo` matches REPO_NAME.

## Golden rules

1. NEVER commit directly to DEFAULT_BRANCH. All work happens on `feat/tt-<id>-<slug>`, `fix/tt-<id>-<slug>`, or `chore/tt-<id>-<slug>` branches.
2. One ticket = one branch = one PR. PR title: `TT-<id>: <ticket title>`. PR body links the Notion ticket URL and includes a test plan.
3. Never start implementation on a ticket whose `AI Stage` is not `Plan Approved`. If asked to, say so and offer /plan-ticket instead.
4. The plan lives in the Notion ticket page body under "## Implementation Plan". Follow it. If reality diverges from the plan, update the plan section in Notion and note why.
5. Update Notion as you go: set `AI Stage`, `Status`, and `Branch` at each transition (see commands). Stale boards are worse than no boards.
6. Run TEST_CMD and LINT_CMD before every push. A PR with failing checks is not "done".
7. If blocked (missing credentials, ambiguous requirement, breaking conflict), set `AI Stage: Blocked`, add a comment on the Notion ticket explaining why, and stop — don't guess.
8. Keep commits small and conventional: `feat(scope): ...`, `fix(scope): ...`, referencing TT-<id> in the body.

## Commands

- /triage — find Needs Plan tickets for this repo, research, write plans, mark Plan Ready
- /plan-ticket TT-<id> — research + plan a single ticket
- /sprint — execute the Current sprint's approved tickets for this repo
- /work TT-<id> — implement one approved ticket end to end (branch → code → tests → PR)
- /ship TT-<id> — merge the PR, verify deploy, close the ticket

## Subagents

Use them; don't do everything in the main thread:

- `researcher` — codebase/context investigation before planning
- `code-reviewer` — reviews the diff before any PR is opened (mandatory)
- `qa-verifier` — verifies acceptance criteria after implementation (mandatory)
