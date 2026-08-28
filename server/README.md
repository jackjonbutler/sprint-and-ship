# Server runtime (always-on)

Runs the agents headless on any Linux box (built on a Hetzner CPX21). The desktop app is no longer required — planning, overnight building, release detection, and reporting all run here. Telegram is the interface: the system messages you questions; you answer by replying `TKT-123: <answer>` in Telegram or commenting on the Notion ticket.

## The private env repo

This public repo is the engine. Your secrets and filled-in prompts live in a PRIVATE sibling repo (suggested name: `sprint-and-ship-env`) with this shape:

```
sprint-and-ship-env/
├── .env                  # from server/.env.example, filled in
├── prompts/              # scheduled-tasks/*.md with {{PLACEHOLDERS}} replaced
└── docker-compose.override.yml   # optional tweaks
```

The server clones both; `docker compose` mounts the env repo over `server/prompts/` and `.env`.

## Bring-up (once, ~1 hour)

1. Hetzner CPX21, Ubuntu 24.04. `apt install docker.io docker-compose-v2 git`.
2. Clone this repo + your env repo to `/opt/`.
3. Auth pieces (all live only in the env repo / server):
   - Claude: run `claude setup-token` locally, put the OAuth token in .env as `CLAUDE_CODE_OAUTH_TOKEN` (bills your Claude subscription), or use `ANTHROPIC_API_KEY`.
   - GitHub: fine-grained PAT (contents read/write + PRs, scoped to your repos) as `GH_TOKEN`.
   - Notion: internal integration token `NOTION_TOKEN` (the hosted OAuth MCP cannot run headless; share your teamspace with the integration).
   - Telegram bot token + chat id, RevenueCat key, GSC service-account JSON.
4. `docker compose build && docker compose run --rm agent bin/selfcheck.sh` — verifies every credential and repo clone.
5. Install the systemd units: `sudo cp server/systemd/* /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable --now sas-*.timer`.

## Schedules (systemd timers)

| Timer | When | Runs |
|---|---|---|
| sas-ops | nightly 19:00 | telegram answer ingest → release detection → blocked follow-ups → sprint triage if the Next/Current sprint has unplanned tickets (`ss-sprint-triage`) |
| sas-build | nightly 01:00 | `bin/night-build.sh` — the overnight build loop |
| sas-weekly | Sun 19:30 | Ship & Learn |

## The overnight build loop (bin/night-build.sh)

For each unchecked ticket in the Current sprint manifest, in order: fresh `claude -p` invocation running the ss-next procedure (fresh context per ticket, exactly like /clear + /next), through to PR + ticket review (`ss-ticket-review`). Questions → Telegram + ticket parked Blocked → loop continues with the next ticket. Two consecutive hard failures → stop and Telegram (don't burn tokens on a broken night). Morning Telegram summary: PRs ready for review, questions asked, anything parked. PRs are NEVER merged overnight — your morning review stays the gate.

## Logs

Every run appends JSONL events to `/var/log/sprint-and-ship/events.jsonl` (run start/end, ticket transitions, questions asked, failures) and full transcripts to `runs/<date>-<job>/`. These are the raw material for sprint-close's improvement synthesis — don't disable them.
