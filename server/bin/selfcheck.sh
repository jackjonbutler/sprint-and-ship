#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
ok=1
claude --version >/dev/null 2>&1 && echo "claude: ok" || { echo "claude: FAIL"; ok=0; }
[ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}${ANTHROPIC_API_KEY:-}" ] && echo "claude auth: set" || { echo "claude auth: MISSING"; ok=0; }
gh auth status >/dev/null 2>&1 && echo "gh: ok" || { echo "gh: FAIL"; ok=0; }
curl -s -H "Authorization: Bearer $NOTION_TOKEN" https://api.notion.com/v1/users/me -H "Notion-Version: 2022-06-28" | grep -q '"type"' && echo "notion: ok" || { echo "notion: FAIL"; ok=0; }
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe" | grep -q '"ok":true' && echo "telegram: ok" || { echo "telegram: FAIL"; ok=0; }
sync_repos && echo "repos: ok" || { echo "repos: FAIL"; ok=0; }
[ "$ok" = 1 ] && { echo "SELFCHECK PASS"; tg "✅ sprint-and-ship server selfcheck passed"; } || { echo "SELFCHECK FAIL"; exit 1; }
