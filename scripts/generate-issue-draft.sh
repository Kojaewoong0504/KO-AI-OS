#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: scripts/generate-issue-draft.sh \
  --title TITLE \
  --purpose TEXT \
  --criteria TEXT [--criteria TEXT ...] \
  --scope-include TEXT [--scope-include TEXT ...] \
  [--scope-exclude TEXT ...] \
  [--constraints TEXT] \
  [--context TEXT] \
  [--expected-output TEXT] \
  --output issue.yml
USAGE
}

quote_yaml() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '"%s"' "$value"
}

title=""
purpose=""
constraints=""
context=""
expected_output=""
output=""
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
    --output)
      output="${2:-}"
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
[[ "${#criteria[@]}" -gt 0 ]] || missing+=("--criteria")
[[ "${#scope_include[@]}" -gt 0 ]] || missing+=("--scope-include")
[[ -n "$output" ]] || missing+=("--output")

if [[ "${#missing[@]}" -gt 0 ]]; then
  echo "Missing required option(s): ${missing[*]}" >&2
  usage
  exit 2
fi

mkdir -p "$(dirname "$output")"

{
  printf 'title: '
  quote_yaml "$title"
  printf '\n'
  printf 'purpose: '
  quote_yaml "$purpose"
  printf '\n'
  echo "criteria:"
  for item in "${criteria[@]}"; do
    [[ -n "$item" ]] || continue
    printf '  - '
    quote_yaml "$item"
    printf '\n'
  done
  echo "scope_include:"
  for item in "${scope_include[@]}"; do
    [[ -n "$item" ]] || continue
    printf '  - '
    quote_yaml "$item"
    printf '\n'
  done
  echo "scope_exclude:"
  if [[ "${#scope_exclude[@]}" -gt 0 ]]; then
    for item in "${scope_exclude[@]}"; do
      [[ -n "$item" ]] || continue
      printf '  - '
      quote_yaml "$item"
      printf '\n'
    done
  else
    echo '  - "없음"'
  fi
  printf 'constraints: '
  quote_yaml "${constraints:-없음}"
  printf '\n'
  printf 'context: '
  quote_yaml "${context:-없음}"
  printf '\n'
  printf 'expected_output: '
  quote_yaml "${expected_output:-코드 변경 / 문서 / 분석 리포트 중 해당 결과물}"
  printf '\n'
} > "$output"

echo "Generated issue draft: $output"
