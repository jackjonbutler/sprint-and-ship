#!/usr/bin/env node
// Blocks `git commit` / `git push` executed while on the default branch.
// Claude Code passes hook input as JSON on stdin.
const { execSync } = require("child_process");

let input = "";
process.stdin.on("data", (d) => (input += d));
process.stdin.on("end", () => {
  try {
    const { tool_input } = JSON.parse(input);
    const cmd = (tool_input && tool_input.command) || "";
    if (!/git\s+(commit|push)/.test(cmd)) return process.exit(0);
    // allow explicit pushes of feature branches even if HEAD is elsewhere
    const branch = execSync("git rev-parse --abbrev-ref HEAD", { encoding: "utf8" }).trim();
    const DEFAULT = process.env.DEFAULT_BRANCH || "main";
    if (branch === DEFAULT) {
      console.error(
        `BLOCKED: you are on '${DEFAULT}'. Create a ticket branch first (feat/tt-<id>-<slug>). See CLAUDE.md golden rule 1.`
      );
      process.exit(2); // exit 2 = block the tool call, feed stderr back to Claude
    }
    process.exit(0);
  } catch {
    process.exit(0); // never break the session on hook errors
  }
});
