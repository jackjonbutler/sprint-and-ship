#!/usr/bin/env bash
# Generic timer entrypoint: run-job.sh <job-name>  → runs /work/prompts/<job-name>.md
source "$(dirname "$0")/lib.sh"
sync_repos
run_agent "$1" "/work/prompts/$1.md"
