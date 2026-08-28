#!/usr/bin/env bash
# Run before every push: fails if anything token-shaped is staged or committed.
# Patterns: Telegram bot tokens, Anthropic/OpenAI keys, GitHub PATs, Notion tokens,
# RevenueCat secrets, AWS keys, private keys, filled .env files.
set -uo pipefail
PATTERNS='[0-9]{8,10}:AA[A-Za-z0-9_-]{30,}|sk-ant-[A-Za-z0-9-]{20,}|sk_[A-Za-z0-9]{25,}|github_pat_[A-Za-z0-9_]{20,}|ghp_[A-Za-z0-9]{30,}|ntn_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA|EC|OPENSSH) PRIVATE KEY'
FAIL=0
if git grep -nE "$PATTERNS" -- ':!scripts/secret-scan.sh' 2>/dev/null; then echo "^^ SECRETS IN TRACKED FILES"; FAIL=1; fi
if git diff --cached | grep -qE "$PATTERNS"; then echo "SECRETS IN STAGED CHANGES"; FAIL=1; fi
if git ls-files | grep -vE "example" | grep -qE "\.env$|service-account.*\.json$"; then echo "ENV/CREDENTIAL FILE TRACKED"; FAIL=1; fi
[ "$FAIL" = 0 ] && echo "secret-scan: clean" || { echo "secret-scan: FAILED — do not push"; exit 1; }
