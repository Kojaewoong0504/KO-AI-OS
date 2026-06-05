#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: scripts/live-smoke-github-issue.sh --repo OWNER/REPO [--timeout-seconds 120]

Creates a temporary complete ai-task issue, waits for ready-for-ai, then closes it.
Requires gh authentication and the repository workflows to be present on GitHub.
USAGE
}

repo=""
timeout_seconds=120

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    --timeout-seconds)
      timeout_seconds="${2:-}"
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

if ! command -v gh >/dev/null 2>&1; then
  echo "Missing required command: gh. Install GitHub CLI and run 'gh auth login'." >&2
  exit 127
fi

gh auth status >/dev/null

body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

cat > "$body_file" <<'BODY'
## 목적
AI OS live smoke test가 pre-hook을 통과하는지 확인한다.

## 수락 기준
- [ ] complete issue receives ready-for-ai

## 범위

**포함:**
- GitHub issue workflow smoke test

**제외:**
- 코드 변경

## 제약
테스트 이슈는 검증 후 닫는다.

## 참고 컨텍스트
scripts/live-smoke-github-issue.sh

## 예상 결과물
ready-for-ai 라벨 확인
BODY

issue_url="$(
  gh issue create \
    --repo "$repo" \
    --label ai-task \
    --title "[AI OS SMOKE] ready-for-ai workflow check" \
    --body-file "$body_file"
)"

issue_number="${issue_url##*/}"
echo "Created smoke issue: #$issue_number"

deadline=$((SECONDS + timeout_seconds))
ready=false

while [[ "$SECONDS" -le "$deadline" ]]; do
  labels="$(gh issue view "$issue_number" --repo "$repo" --json labels --jq '.labels[].name' || true)"
  if printf '%s\n' "$labels" | grep -qx "ready-for-ai"; then
    ready=true
    break
  fi
  sleep 5
done

if [[ "$ready" != true ]]; then
  echo "ready-for-ai label was not observed on issue #$issue_number within ${timeout_seconds}s" >&2
  gh issue close "$issue_number" --repo "$repo" --comment "AI OS smoke test failed: ready-for-ai label was not observed." >/dev/null || true
  exit 1
fi

gh issue close "$issue_number" --repo "$repo" --comment "AI OS smoke test passed: ready-for-ai label observed." >/dev/null

echo "live github issue smoke test passed for $repo issue #$issue_number"
