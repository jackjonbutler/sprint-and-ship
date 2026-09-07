# Vendored third-party skills

## emilkowalski/skills — MIT

Design and animation craft skills by Emil Kowalski (Vercel, Linear).
Source: https://github.com/emilkowalski/skills — vendored, not modified.
Licence: MIT, see LICENSE-emilkowalski-skills.

Vendored (rather than installed via `npx skills add`) because the build agent runs
headless in a container with no interactive install step: the Dockerfile copies
`skills/` to `/root/.claude/skills`, so anything here is available to every agent run.

Directories: animate, animate-expo, animation-vocabulary, apple-design, ask-sonner,
emil-design-eng, find-animation-opportunities, improve-animations, pick-ui-library,
prototype, review-animations, write-swift.

To update: re-clone upstream and copy `skills/*` over these directories.
