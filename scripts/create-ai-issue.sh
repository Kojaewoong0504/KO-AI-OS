#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: scripts/create-ai-issue.sh \
  --title TITLE \
  --purpose TEXT \
  --criteria TEXT [--criteria TEXT ...] \
  --scope-include TEXT [--scope-include TEXT ...] \
  [--scope-exclude TEXT ...] \
  [--constraints TEXT] \
  [--context TEXT] \
  [--expected-output TEXT]
USAGE
}

require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "Missing required command: gh. Install GitHub CLI and run 'gh auth login'." >&2
    exit 127
  fi
}

has_non_empty_item() {
  local item
  for item in "$@"; do
    [[ -n "$item" ]] && return 0
  done
  return 1
}

title=""
purpose=""
constraints=""
context=""
expected_output=""
criteria=()
scope_include=()
scope_exclude=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)
      title="${2:-}"
      shift 2
      ;;
    --purpose)
      purpose="${2:-}"
      shift 2
      ;;
    --criteria)
      criteria+=("${2:-}")
      shift 2
      ;;
    --scope-include)
      scope_include+=("${2:-}")
      shift 2
      ;;
    --scope-exclude)
      scope_exclude+=("${2:-}")
      shift 2
      ;;
    --constraints)
      constraints="${2:-}"
      shift 2
      ;;
    --context)
      context="${2:-}"
      shift 2
      ;;
    --expected-output)
      expected_output="${2:-}"
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

missing=()
[[ -n "$title" ]] || missing+=("--title")
[[ -n "$purpose" ]] || missing+=("--purpose")
if [[ "${#criteria[@]}" -eq 0 ]] || ! has_non_empty_item "${criteria[@]}"; then
  missing+=("--criteria")
fi
if [[ "${#scope_include[@]}" -eq 0 ]] || ! has_non_empty_item "${scope_include[@]}"; then
  missing+=("--scope-include")
fi

if [[ "${#missing[@]}" -gt 0 ]]; then
  echo "Missing required option(s): ${missing[*]}" >&2
  usage
  exit 2
fi

require_gh

body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

{
  echo "## 목적"
  echo "$purpose"
  echo
  echo
  echo "## 수락 기준"
  for item in "${criteria[@]}"; do
    [[ -n "$item" ]] && echo "- [ ] $item"
  done
  echo
  echo "## 범위"
  echo
  echo "**포함:**"
  for item in "${scope_include[@]}"; do
    [[ -n "$item" ]] && echo "- $item"
  done
  echo
  echo "**제외:**"
  if [[ "${#scope_exclude[@]}" -gt 0 ]]; then
    for item in "${scope_exclude[@]}"; do
      [[ -n "$item" ]] && echo "- $item"
    done
  else
    echo "- 없음"
  fi
  echo
  echo "## 제약"
  echo "${constraints:-없음}"
  echo
  echo
  echo "## 참고 컨텍스트"
  echo "${context:-없음}"
  echo
  echo
  echo "## 예상 결과물"
  echo "${expected_output:-코드 변경 / 문서 / 분석 리포트 중 해당 결과물}"
} > "$body_file"

gh issue create \
  --label ai-task \
  --title "$title" \
  --body-file "$body_file"
