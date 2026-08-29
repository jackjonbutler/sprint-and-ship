#!/usr/bin/env bash
# Append one status line to the Notion "Pipeline Status" page.
# Usage: notion-status.sh "<emoji> <text>"
# Requires NOTION_TOKEN and NOTION_STATUS_PAGE_ID in the environment. Never fails a run.
[ -z "${NOTION_TOKEN:-}" ] || [ -z "${NOTION_STATUS_PAGE_ID:-}" ] && exit 0
TEXT="$(date -u '+%Y-%m-%d %H:%M') UTC — $1"
python3 - "$NOTION_TOKEN" "$NOTION_STATUS_PAGE_ID" "$TEXT" <<'PY' 2>/dev/null || true
import json,sys,urllib.request
tok,page,text = sys.argv[1],sys.argv[2],sys.argv[3]
body = {"children":[{"object":"block","type":"bulleted_list_item",
  "bulleted_list_item":{"rich_text":[{"type":"text","text":{"content":text[:1900]}}]}}]}
req = urllib.request.Request(f"https://api.notion.com/v1/blocks/{page}/children",
  data=json.dumps(body).encode(), method="PATCH",
  headers={"Authorization":f"Bearer {tok}","Notion-Version":"2022-06-28","Content-Type":"application/json"})
urllib.request.urlopen(req, timeout=15).read()
PY
