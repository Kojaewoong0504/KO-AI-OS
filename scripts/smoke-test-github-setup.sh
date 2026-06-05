#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: scripts/smoke-test-github-setup.sh --repo REPO_DIR
USAGE
}

repo=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$repo" ]]; then
  echo "Missing required option: --repo" >&2
  usage
  exit 2
fi

required_files=(
  ".github/ISSUE_TEMPLATE/ai-task.yml"
  ".github/workflows/pre-hook.yml"
  ".github/workflows/post-hook.yml"
  ".github/workflows/label-sync.yml"
  ".github/labels.yml"
  "harness/ai-rules.md"
  "harness/github-issue-protocol.md"
  "harness/github-mcp-protocol.md"
  "scripts/create-ai-issue.sh"
  "scripts/generate-issue-draft.sh"
  "scripts/live-smoke-github-issue.sh"
  "scripts/list-ready-ai-issues.sh"
  "scripts/bootstrap-ai-os.sh"
  "scripts/upgrade-ai-os.sh"
  "AI_OS_VERSION"
)

for file in "${required_files[@]}"; do
  if [[ ! -e "$repo/$file" ]]; then
    echo "Missing required file: $file" >&2
    exit 1
  fi
done

for label in ai-task ready-for-ai needs-clarification blocked; do
  if ! grep -q "name: $label" "$repo/.github/labels.yml"; then
    echo "Missing label declaration: $label" >&2
    exit 1
  fi
done

if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    echo "gh auth status: authenticated"
  else
    echo "gh auth status: not authenticated"
  fi
else
  echo "gh auth status: gh not installed"
fi

echo "github setup smoke test passed"
