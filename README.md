# Sprint and Ship

**A one-man dev team system**: Notion for tickets and sprints, Claude (Code + scheduled agents) for planning, building, and reviewing, GitHub for PRs — plus a measurement loop that checks whether what you shipped actually worked, and turns the results into build-in-public content.

This is the real system running [Trips Together](https://tripstogether.co.uk) (Flutter app + Express API + Next.js site), published with secrets replaced by `{{PLACEHOLDERS}}`.

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
Detects actual production releases (Vercel / Komodo / App+Play Store polling)
        ↓  weekly scheduled agent (Sunday 7pm)
Ship & Learn: checks each change's success metric FROM ITS LIVE DATE
(PostHog · Search Console · RevenueCat) → Changelog verdicts →
weekly report → build-in-public content drafts into a tracked pipeline
```

Three human decisions per ticket: what to build · approve the plan · approve the PR. Everything else is pipeline.

## What's in here

| Path | What |
|---|---|
| `workspace/` | Cross-repo orchestrator: drop into a parent folder containing your repos. Commands route tickets to the right repo. |
| `repo-kit/` | Per-repo kit: CLAUDE.md config template, commands, subagents, a hook that blocks commits to protected branches. |
| `scheduled-tasks/` | Prompts for the two scheduled agents (Claude desktop/Cowork): nightly triage + release detection, weekly Ship & Learn. |
| `notion/SCHEMA.md` | The Notion setup: ticket properties, Changelog + Content Tracker databases, views. |
| `docs/` | System design rationale + one-page workflow PDF. |
| `INSTALL.md` | Setup, end to end. |

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
