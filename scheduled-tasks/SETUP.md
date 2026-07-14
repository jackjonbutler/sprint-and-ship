# Setting up the scheduled agents (Claude desktop / Cowork)

The two agents run as **scheduled tasks** in the Claude desktop app (Cowork mode). You create them by pasting a prompt into a Cowork chat. Do this once per task.

## Before you paste
1. Open `nightly-triage.md` and `weekly-ship-and-learn.md` in this folder.
2. Replace every `{{PLACEHOLDER}}` with your real values (Notion collection IDs, Telegram token/chat id, bundle ID, API URL, RevenueCat key). Keep the edited copies OUT of git — they now contain secrets.
3. Edit the repo-mapping section at the top of each to match your repos.
4. In the Cowork session where you'll paste, connect your repo folders (the tasks inherit access when you attach the folders to the task afterwards).

## Prompt 1 — create the nightly agent
Paste this into Claude Cowork, then paste the full edited contents of `nightly-triage.md` where indicated:

> Create a scheduled task with id `nightly-triage`, description "Daily evening: research new tickets against the repos, write plans in Notion, Telegram me any questions", running every day at 7pm local (cron `0 19 * * *`). Use exactly the following as the task prompt, verbatim:
>
> [PASTE THE FULL EDITED CONTENTS OF nightly-triage.md HERE]

## Prompt 2 — create the weekly agent
> Create a scheduled task with id `weekly-ship-and-learn`, description "Sunday evening: weekly report — shipped changes vs analytics outcomes + content drafts", running Sundays at 7pm local (cron `0 19 * * 0`). Use exactly the following as the task prompt, verbatim:
>
> [PASTE THE FULL EDITED CONTENTS OF weekly-ship-and-learn.md HERE]

## After creating each task
- In the Scheduled sidebar, open the task and **attach your repo folders** — scheduled runs do NOT inherit the chat session's folders.
- Click **Run now** once and approve the permission prompts (Notion, bash, web fetch, analytics connectors) — approvals stick to the task, so future runs never pause.
- The Claude app must be open at the scheduled time; missed runs execute on next launch.

## Updating a task later
Paste into Cowork: "Update the scheduled task `nightly-triage`: replace its prompt with the following, keep the schedule" + the new prompt. (Or edit the task's SKILL.md file directly in your Claude Scheduled folder.)
