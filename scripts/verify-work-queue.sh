#!/usr/bin/env bash
set -euo pipefail

pre_hook=".github/workflows/pre-hook.yml"
rules="harness/ai-rules.md"
readme="README.md"

grep -q "labels: \\['ready-for-ai'\\]" "$pre_hook"
grep -q "name: 'ready-for-ai'" "$pre_hook"
grep -q "labels: \\['needs-clarification'\\]" "$pre_hook"

grep -q "is:issue is:open label:ai-task label:ready-for-ai -label:needs-clarification -label:blocked" "$rules"
grep -q "ready-for-ai" "$readme"

echo "work queue verification passed"
