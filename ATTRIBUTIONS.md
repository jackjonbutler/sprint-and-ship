# ATTRIBUTIONS

Sprint and Ship contains no verbatim code or prose from other skill packages — every file was written for this system. The workflow *patterns*, however, are openly borrowed, and deserve credit:

- **GSD (get-shit-done)** — https://github.com/gsd-build/get-shit-done (MIT, © Lex Christopherson / TÂCHES). The context-management architecture: lean orchestrator + manifest as state, fresh 100% context per unit of work, explicit transition/completion protocol ("clear context, run the next command"). ss-sprint-plan + ss-next are our Notion-native reimplementation of the plan-phase/execute-phase/transition pattern.
- **Superpowers** — subagent-driven development and verification-before-completion: the mandatory qa-verifier ("executed evidence, never 'looks right'") and cold-context code-reviewer gates.
- **gstack** — © Garry Tan (MIT). The plan-review gate pattern (a human approval that the agent cannot bypass) and post-deploy verification thinking behind our release detection.
- **dev-stack** — https://github.com/mike-kirby-dev/dev-stack — the packaging model this repo follows: prefixed skills, idempotent symlink installer, drift-conscious updates, ATTRIBUTIONS.md itself.

## Vendored / derived skills

Unlike the sections above (patterns only), these files contain modified copies of upstream skill files, cherry-picked via dev-stack:

| Skill | Upstream | License | Modifications |
|---|---|---|---|
| `skills/sp-systematic-debugging/` | obra/superpowers via dev-stack | MIT (`licenses/superpowers-LICENSE`) | attribution header only |
| `skills/sp-brainstorming/` | obra/superpowers via dev-stack | MIT (`licenses/superpowers-LICENSE`) | output adapter: converges into creating a Needs Plan ticket instead of proceeding to implementation |
| `skills/gs-plan-eng-review/` | garrytan/gstack via dev-stack | MIT (`licenses/gstack-LICENSE`) | note pointing the review at the Notion ticket's Implementation Plan section |
| `skills/ss-quick/` | derived from gsd-build/get-shit-done `gsd-quick` via dev-stack | MIT (`licenses/gsd-LICENSE`) | rewritten: Notion tickets/Changelog replace the `.planning/` state tree; boundary rules; mandatory code-reviewer |
