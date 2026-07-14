# Install

Prereqs: Notion workspace · Claude desktop app (Cowork mode, for scheduled agents) · Claude Code in VS Code/terminal · GitHub CLI (`gh auth login`) · optionally PostHog, Google Search Console, RevenueCat, Telegram.

## 1. Notion
Follow `notion/SCHEMA.md`: extend your tasks database with AI Stage / Branch / Repo, create the Changelog and Content Tracker databases and the views. Note the collection IDs (fetch any database via the Notion MCP to see its `collection://` ID).

## 2. Per repo
Copy `repo-kit/CLAUDE.md` + `repo-kit/.claude/` into each repo. Edit the Repo config block at the top of CLAUDE.md: REPO_NAME (must match your Notion Repo select), DEFAULT_BRANCH (integration), PROD_BRANCH, TEST_CMD, LINT_CMD, DEPLOY. Commit via PR.
Add `.mcp.json` with the Notion MCP (`https://mcp.notion.com/mcp`, http transport); authenticate once via `/mcp` in Claude Code.

## 3. Workspace (single-window, multi-repo)
Copy `workspace/CLAUDE.md` + `workspace/.claude/` into the PARENT folder containing your repos (must not itself be a git repo). Edit the repo map table and the protected-branch list in `.claude/hooks/guard-main.js`. Open Claude Code here for all sprint work.

## 4. Scheduled agents (Claude desktop / Cowork)
Create two scheduled tasks from `scheduled-tasks/*.md`, replacing every `{{PLACEHOLDER}}`:
- nightly-triage: daily, evening. Attach your repo folders to the task. Needs Notion connector.
- weekly-ship-and-learn: Sundays. Same folders. Needs Notion + PostHog connectors, GSC access.
Run each once manually to pre-approve its tool permissions.

## 5. Telegram (questions + digests)
@BotFather → /newbot → token. Message your bot once, then GET /getUpdates for your chat_id. Fill both placeholders. Tokens live only in the local task files — never in git.

## 6. RevenueCat (optional)
Project → API keys → new v2 secret key with Charts & Metrics: Read. Fill `{{REVENUECAT_API_KEY}}` and `{{REVENUECAT_PROJECT_ID}}` (from your dashboard URL).

## 7. Release detection
- Vercel-style (merge = live): nothing to do.
- Server deploys: expose git SHA in a /health or /version endpoint; the nightly task compares it to origin/main. Until then it assumes merge-to-main = deployed.
- Mobile: keep your app version bumped in pubspec/build config at each release cut; the nightly task polls `itunes.apple.com/lookup?bundleId=...` and the Play Store listing until both show the version, then marks changes Live.

## 8. Branch protection (recommended)
Require PRs on your integration and prod branches in GitHub settings. The guard hook blocks the agent; branch protection blocks everyone.
