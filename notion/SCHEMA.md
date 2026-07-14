# Notion schema

## Tasks database (extend your existing one)
| Property | Type | Values |
|---|---|---|
| ID | Unique ID | prefix e.g. TT → tickets referenced as TT-123; branch names contain tt-123 so Notion's GitHub integration auto-links PRs |
| Status | Status | Backlog / Not started / In progress / QA / Done (+ your own) |
| AI Stage | Select | Needs Plan · Researching · Plan Ready · Plan Approved · Building · PR Open · Blocked |
| Branch | Text | written by the agent at branch creation |
| Repo | Select | one option per repository, matching each repo's REPO_NAME |

Views: **Plans to review** (AI Stage = Plan Ready) · **Blocked** (AI Stage = Blocked). Add AI Stage + Repo columns to your backlog/sprint views.

## Sprints database
Standard Notion sprints (Sprint status: Current/Next/Past, task relation, completion rollup). The /sprint-plan command writes an "## Execution Order" manifest into the Current sprint's page body; /next consumes it.

## Ship & Learn home (a page)
Weekly report sub-pages land here. Under it, two databases:

### Changelog
| Property | Type | Notes |
|---|---|---|
| Change | Title | |
| Ship date | Date | merge date |
| Repo | Select | same options as Tasks |
| Ticket | Relation → Tasks | |
| Success metric | Text | from the ticket plan |
| Verdict | Select | Too early · Moved · Flat · Regressed · Not instrumented |
| Release status | Select | Merged · In review · Live |
| Live date | Date | measurement anchor — set by nightly release detection |
| Version | Text | mobile app version carrying this change |
| Last checked | Date | |
| Story notes | Text | dated lines accumulate weekly — multi-week narratives |

### Content Tracker
| Property | Type | Notes |
|---|---|---|
| Title | Title | script in page body |
| Platform | Select | X/Twitter · LinkedIn · TikTok/Reels · Instagram |
| Status | Select | Draft · Ready · Recorded · Posted · Skipped |
| Posted date / Post URL | Date / URL | |
| Views · Likes · Comments · Shares · Saves · Follows gained | Number | you fill these; the weekly run learns from them |
| Performance notes | Text | qualitative signal |
| Week | Text | source report week |
| Source changes | Relation → Changelog | |

View: **Pipeline** board grouped by Status.
