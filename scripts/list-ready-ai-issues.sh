#!/usr/bin/env bash
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "Missing required command: gh. Install GitHub CLI and run 'gh auth login'." >&2
  exit 127
fi

gh issue list \
  --state open \
  --label ai-task \
  --label ready-for-ai \
  --search "-label:needs-clarification -label:blocked"
