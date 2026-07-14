# System Design — Professional One-Man Dev Team

A worked design for a one-person, multi-repo product team · July 2026

## What this system is

A pipeline that separates the four jobs you currently do interleaved in one chat window — deciding what to build, planning how, building it, and verifying it — into distinct stages with explicit handoffs. Notion holds the state, GitHub holds the code, Claude Code does the labour, and you make the three decisions that matter: which tickets, approve the plan, approve the PR.

The design borrows from the dev-stack repo you referenced: GSD's phase discipline (discuss → plan → execute → verify → ship), Superpowers' subagent-driven development and verification-before-completion, and gstack's plan-review gates. Rather than installing those skills wholesale, the kit encodes the same ideas as five slash commands and three subagents tuned to your actual Notion schema.

## State model

Your existing `the tasks database` database is the single source of truth. Two orthogonal properties track a ticket:

**Status** (yours, human workflow): Shiny Penny / Backlog → Not started → In progress → QA → Done. Unchanged.

**AI Stage** (new, pipeline state): Needs Plan → Researching → Plan Ready → *Plan Approved* → Building → PR Open → (cleared on Done). Blocked is reachable from anywhere. The italicised transition is the one only you can make — it is the system's safety gate. Claude will refuse to write code for a ticket that isn't Plan Approved.

Supporting properties: **Branch** (written by Claude at branch creation), **Repo** (routes tickets to the right codebase — each repo's CLAUDE.md declares which Repo value it owns), and your existing **GitHub Pull Requests** relation (Notion's GitHub sync links PRs automatically when the branch contains the ticket ID).

Sprints stay exactly as you run them in `the sprints database`: you assemble a sprint by relating approved tickets to the Current sprint. Claude never assigns tickets to sprints.

## Stage by stage

**1 · Ticket intake.** You write tickets in Notion as thoughts occur — title, rough description, Repo, Priority, AI Stage = Needs Plan. Quality of the description matters less than usual because the next stage's job is to turn vagueness into a reviewable plan or a Blocked comment asking the right questions.

**2 · Research & planning (scheduled).** A GitHub Action in each repo runs Claude Code headless on weekday mornings (plus a manual Run button). It queries Notion for Needs Plan tickets matching its repo, runs the `researcher` subagent over the codebase, and writes a structured Implementation Plan into the ticket page: goal, findings, numbered approach with exact files, out-of-scope, acceptance criteria as checkboxes, test plan, estimate and risk. Ambiguous tickets get Blocked with specific questions instead of a guessed plan. The same flow runs interactively as /triage or /plan-ticket TKT-123 when you don't want to wait for the schedule. This stage runs in CI rather than your laptop because planning benefits from repo checkout but needs no supervision — it's the most automatable stage and the one you chose scheduled polling for.

**3 · Your review (the coffee stage).** In Notion, read plans in a "Plans to review" view, comment or edit, flip to Plan Approved, and drag into the sprint. Rejecting a plan = leave a comment and run /plan-ticket again; the command explicitly reads and addresses your comments. This is deliberately the highest-leverage five minutes of the system: correcting a plan costs minutes, correcting a wrong implementation costs hours.

**4 · Execution (/sprint or /work).** In VS Code you say /sprint. Claude reports the board, proposes an execution order (priority → dependencies → smallest first), and waits for your confirmation — then runs each ticket through /work: fresh branch off main named feat/tkt-<id>-<slug>, implement per plan in small conventional commits, tests and lint run continuously, Notion updated at every transition so the board is always live. Small deviations from plan get recorded back into the ticket; large ones stop the work and get Blocked. One ticket = one branch = one PR, sequentially — parallelism for a solo dev creates merge-conflict overhead that outweighs the speed gain, and sequential PRs keep your review queue linear. (When you do want parallelism, git worktrees + two VS Code windows work fine with this system; the branch discipline already isolates the work.)

**5 · Verification (before you ever see it).** Two mandatory subagents gate every PR. `qa-verifier` checks each acceptance criterion against executed evidence — code reference plus passing test, never "looks right" — and ticks the checkboxes in the Notion plan. `code-reviewer` then reviews the full diff for correctness, security, unplanned scope, and codebase consistency; blocking findings must be fixed before the PR opens. This is the Superpowers verification-before-completion pattern: the agent that wrote the code never certifies it alone.

**6 · Your QA + ship.** The PR arrives titled TKT-<id> with the ticket linked, a test plan, and (for web) a Vercel preview URL in the ticket comments. You click around, review the diff at whatever depth the ticket deserves, then /ship TKT-123: checks green → squash-merge → deploy verified against a smoke URL (Vercel prod) or build triggered (EAS for mobile) → failed deploy auto-reverts and Blocks the ticket → success closes it with merge SHA and changelog comment.

## Branching & deployment model

Trunk-based with short-lived ticket branches. `main` is always deployable and is protected by a Claude Code hook (`guard-main.js`) that blocks any `git commit`/`git push` while on main — defence in depth alongside the CLAUDE.md rule, because instructions drift in long sessions but hooks don't. Squash merges keep history one-commit-per-ticket, which makes reverts (the /ship failure path) trivial.

Deploys are config, not architecture: each repo's CLAUDE.md declares its DEPLOY block. Web: Vercel previews per PR, auto-prod on merge, /ship just verifies. Mobile: /ship triggers EAS update/build on merge. Backend/other: whatever the repo declares.

## Skills & agent orchestration

The kit is itself a skills package in the dev-stack mould — versionable, installable per repo, improvable over time. Extension path, in order of value: add a `debugger` subagent (systematic-debugging pattern) for when /work hits failing tests it can't quickly fix; add gstack-style multi-perspective plan reviews (eng/design/CEO lenses) as optional /triage depth for L-sized tickets; add a `canary` post-deploy smoke skill wired into /ship; keep all repos' kits in one `tt-dev-kit` repo and symlink/copy in, so improvements propagate (dev-stack's install.sh model).

Principles the kit follows and future skills should too: subagents get the narrowest tool set that does the job (researcher can't write; reviewer can't execute arbitrary bash); every stage writes its state to Notion so any session can be resumed cold; gates are structural (hooks, refusal rules, status checks) rather than politeness.

## Failure modes & recovery

Session dies mid-ticket → state is in Notion (AI Stage, Branch) and git; open a new session, /work TKT-123 resumes from the branch. Bad plan approved → deviations rule catches small errors, Blocked catches large ones; worst case you review a wrong PR and reject it — main is untouched. Deploy breaks prod → /ship's smoke check reverts the merge automatically. Claude goes off-piste → guard-main hook stops the worst outcome; everything else is a branch you can delete.

## What stays manual, by design

Writing tickets (what to build is the business), approving plans, sprint assembly, PR approval and anything user-facing enough to deserve human eyes, and rotating credentials/secrets. Everything else is Claude's job.
