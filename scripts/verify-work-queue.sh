#!/usr/bin/env bash
set -euo pipefail

pre_hook=".github/workflows/pre-hook.yml"
rules="harness/ai-rules.md"
protocol="harness/github-issue-protocol.md"
readme="README.md"

grep -q "labels: \\['ready-for-ai'\\]" "$pre_hook"
grep -q "name: 'ready-for-ai'" "$pre_hook"
grep -q "labels: \\['needs-clarification'\\]" "$pre_hook"

grep -q "is:issue is:open label:ai-task label:ready-for-ai -label:needs-clarification -label:blocked" "$rules"
grep -q "scripts/create-ai-issue.sh" "$protocol"
grep -q "scripts/list-ready-ai-issues.sh" "$protocol"
grep -q "ready-for-ai" "$readme"
grep -q "scripts/create-ai-issue.sh" "$readme"
grep -q "scripts/init-ai-os.sh" "$readme"
test -f "templates/agents/AGENTS.md.tpl"
test -f "templates/agents/harness-ai-rules.md.tpl"
test -f "ai-os.project.example.yml"

echo "work queue verification passed"
