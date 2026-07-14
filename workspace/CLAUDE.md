# Trips Together — Workspace Orchestrator

This is the CROSS-REPO workspace. Commands here route tickets to the right repo by the ticket's `Repo` property. This folder is NOT a git repo — never run git here; always `cd` into a repo first.

## Repo map (only these three — ignore all sibling folders)

| Notion `Repo` | Folder | DEFAULT_BRANCH (PRs target) | PROD_BRANCH | TEST_CMD | LINT_CMD |
|---|---|---|---|---|---|
| backend | tripsbackend/ | development | main | npm run test:<area> (no aggregate; run test:* scripts touching changed services) | none — skip |
| frontend | trips-frontend/ | development | main (Codemagic deploys; flutterflow = frozen legacy) | flutter test | flutter analyze |
| brochure site | tripsBrochureSite/ | master | master (Vercel auto-deploys) | npm run build (build is the regression gate) | npm run lint |

If a repo's own CLAUDE.md exists in its folder, its Repo config block overrides this table. Each repo also has ARCHITECTURE.md / SYSTEM.md / GLOSSARY.md — read before coding (on the development branch if not in the working tree yet).

## Notion

- Tickets: "Tasks - Tech" `collection://{{TASKS_DB_COLLECTION_ID}}` — ticket key = ID property, referred to as TT-<ID>
- Sprints: "Sprints - Tech" `collection://{{SPRINTS_DB_COLLECTION_ID}}`
- `AI Stage`: Needs Plan → Researching → Plan Ready → Plan Approved → Building → PR Open (→ Blocked)
- `Status`: Backlog → Not started → In progress → QA → Done

## Golden rules (apply in whichever repo you cd into)

1. NEVER commit to a repo's DEFAULT_BRANCH or PROD_BRANCH. Work on `feat/tt-<id>-<slug>` (or fix/, chore/) cut from DEFAULT_BRANCH.
2. One ticket = one branch = one PR, titled `TT-<id>: <title>`, body links the Notion ticket + test plan. PRs target DEFAULT_BRANCH — never PROD_BRANCH.
3. No implementation unless `AI Stage` = "Plan Approved". The plan lives in the ticket body under "## Implementation Plan" — follow it; record deviations back to Notion.
4. Update Notion at every transition (AI Stage, Status, Branch). Run the repo's TEST_CMD + LINT_CMD before every push.
5. Blocked beats guessed: set AI Stage = Blocked + a Notion comment with specific questions, then stop.
6. Production releases are deliberate development → main merges (backend: Komodo; frontend: Codemagic). Brochure site: merge to master deploys.
7. Mandatory subagents: qa-verifier after implementation, code-reviewer before any PR.

## Commands

/sprint-plan — order the Current sprint (ALL repos), write manifest to the sprint page
/next — execute the next manifest ticket in a fresh context, routed to its repo, then stop
/work TT-<id> — one ticket end to end, routed by its Repo property
/plan-ticket TT-<id> — research + plan one ticket in its repo
/ship TT-<id> — merge that ticket's PR in its repo, update Notion
