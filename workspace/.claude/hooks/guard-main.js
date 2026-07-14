#!/usr/bin/env node
// Workspace-level guard: blocks git commit/push on a protected branch of any Trips Together repo.
const { execSync } = require("child_process");
const path = require("path");
const PROTECTED = {
  "tripsbackend": ["development", "main"],
  "trips-frontend": ["development", "main", "flutterflow"],
  "tripsBrochureSite": ["master"],
};
let input = "";
process.stdin.on("data", (d) => (input += d));
process.stdin.on("end", () => {
  try {
    const { tool_input } = JSON.parse(input);
    const cmd = (tool_input && tool_input.command) || "";
    if (!/git\s+(commit|push)/.test(cmd)) return process.exit(0);
    // which repo does the command touch?
    const repos = Object.keys(PROTECTED).filter((r) => cmd.includes(r));
    // no repo named: check all three (cwd is workspace root; bare git would fail anyway)
    const targets = repos.length ? repos : Object.keys(PROTECTED);
    for (const r of targets) {
      let branch;
      try {
        branch = execSync(`git -C ${JSON.stringify(path.join(process.cwd(), r))} rev-parse --abbrev-ref HEAD`, { encoding: "utf8" }).trim();
      } catch { continue; }
      if (repos.length === 0) continue; // ambiguous command: don't block on unrelated repos' state
      if (PROTECTED[r].includes(branch)) {
        console.error(`BLOCKED: ${r} is on protected branch '${branch}'. Cut a ticket branch first (feat/tt-<id>-<slug>). Workspace CLAUDE.md rule 1.`);
        process.exit(2);
      }
    }
    process.exit(0);
  } catch { process.exit(0); }
});
