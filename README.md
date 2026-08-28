# Sprint and Ship

**A one-man dev team system**: Notion for tickets and sprints, Claude (Code + scheduled agents) for planning, building, and reviewing, GitHub for PRs — plus a measurement loop that checks whether what you shipped actually worked, and turns the results into build-in-public content.

This is a real production system (originally built for a three-repo product: mobile app + API + marketing site), published as a template — all IDs and secrets are `{{PLACEHOLDERS}}`, all names are examples. Point it at your own repos and Notion workspace via INSTALL.md.

## The loop

```
You file a ticket in Notion (AI Stage: Needs Plan)
        ↓  nightly scheduled agent (7pm)
Researches your actual codebases → writes an Implementation Plan
(with a declared success metric) into the ticket → Plan Ready
        ↓  you, over coffee (5 min)
Review plans → approve (Plan Approved) → drag into sprint
        ↓  one Claude Code window, workspace-level
/sprint-plan → manifest on the sprint page
/clear → /next → one ticket per fresh context (GSD-style):
branch → build → qa-verifier → code-reviewer → PR
        ↓  you
Review PR → /ship → merges to development
development → main promotion = deliberate release
        ↓  nightly agent
Detects actual production releases (instant-deploy hosts, server SHA checks, App/Play Store polling)
        ↓  weekly scheduled agent (Sunday 7pm)
Ship & Learn: checks each change's success metric FROM ITS LIVE DATE
(PostHog · Search Console · RevenueCat) → Changelog verdicts →
weekly report → build-in-public content drafts into a tracked pipeline
```

Three human decisions per ticket: what to build · approve the plan · approve the PR. Everything else is pipeline.

## Quick start

```
git clone https://github.com/jackjonbutler/sprint-and-ship.git ~/sprint-and-ship
cd ~/sprint-and-ship
bash install.sh        # symlinks skills into ~/.claude/skills (use --copy on Windows without dev mode)
```

Then follow `INSTALL.md` for the Notion schema, workspace setup, and scheduled agents. Update later with `git pull` — symlinked skills pick changes up automatically.

## What's in here

| Path | What |
|---|---|
| `skills/` | Twelve skills: `ss-sprint-triage` (plan a whole sprint as one unit — plans that know about each other), `ss-ticket-review` (per-ticket cycle review feeding the Improvement Log), the seven `ss-*` pipeline verbs (sprint-plan, next, work, plan-ticket, ship, triage, sprint-close) + `ss-quick` (guarded fast lane) + vendored `sp-brainstorming` (idea → well-formed ticket), `sp-systematic-debugging`, and `gs-plan-eng-review` (deep review for L tickets). |
| `install.sh` / `uninstall.sh` | Idempotent symlink installer, dev-stack style. |
| `workspace/` | Cross-repo orchestrator: drop into a parent folder containing your repos. Commands route tickets to the right repo. |
| `repo-kit/` | Per-repo kit (alternative to global skills, plus the agents + guard hook): CLAUDE.md config template, commands, subagents, a hook that blocks commits to protected branches. |
| `scheduled-tasks/` | Prompts for desktop (Cowork) scheduling — the laptop-hosted way to run the agents. |
| `server/` | Always-on runtime: Docker + systemd timers for a Linux server. Overnight build loop, sprint triage, release detection, weekly reports — no desktop required. Questions reach you on Telegram; reply `TKT-123: answer` and the system picks it up. |
| `notion/SCHEMA.md` | The Notion setup: ticket properties, Changelog + Content Tracker databases, views. |
| `docs/` | System design rationale + one-page workflow PDF. |
| `scripts/sync-kit.sh` | Push kit updates out to your repos (canonical-source flow). |
| `scripts/secret-scan.sh` | Run before every push — blocks token-shaped strings and env files. Wire as a pre-push hook: `ln -s ../../scripts/secret-scan.sh .git/hooks/pre-push` |
| `ATTRIBUTIONS.md` | Where the patterns come from (GSD, Superpowers, gstack, dev-stack). |
| `INSTALL.md` | Setup, end to end. |

## The self-improving loop

Every ticket ends with `ss-ticket-review`: not a code review, a *cycle* review — was the plan accurate, did research miss things, did the gates catch anything, where was the friction? Observations land in an **Improvement Log** with concrete proposed changes. At `ss-sprint-close`, they're synthesized: recurring patterns become tickets with `Repo = pipeline`, planned and built by the same pipeline they improve — through the same human approval gates as product code. Max 3 pipeline tickets per sprint, and one-off noise gets explicitly rejected, so the system improves itself without disappearing up itself.

## Design principles

- **Plan-approval gate**: the agent refuses to build anything a human hasn't approved. Correcting a plan costs minutes; correcting a wrong build costs hours.
- **Fresh context per ticket** (GSD-style): a lean /sprint-plan writes a manifest; each /next gets 100% context for exactly one ticket, then stops.
- **State lives in Notion + git, never in conversations**: any session can die and resume.
- **Subagents as context firewalls**: researcher burns tokens, returns a distilled report; reviewer and QA see the diff cold, unbiased by the builder's assumptions.
- **Merged ≠ live**: release detection polls the stores/servers; metrics are measured from the date users actually got the change.
- **Gates are structural**: hooks and status checks, not politeness. Instructions fade over long contexts; hooks don't.

## Credits

Workflow patterns drawn from [GSD](https://github.com/gsd-build/get-shit-done), gstack, and Superpowers (discovered via [dev-stack](https://github.com/mike-kirby-dev/dev-stack)) — rebuilt natively for a Notion + Claude Code + Cowork stack.

MIT licensed. Built by Jack Butler with Claude.
