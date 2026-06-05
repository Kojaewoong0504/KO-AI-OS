#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: scripts/init-ai-os.sh --profile ai-os.project.yml --output TARGET_DIR [--force]
USAGE
}

profile=""
output=""
force=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      profile="${2:-}"
      shift 2
      ;;
    --output)
      output="${2:-}"
      shift 2
      ;;
    --force)
      force=true
      shift
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

if [[ -z "$profile" || -z "$output" ]]; then
  echo "Missing required option: --profile and --output" >&2
  usage
  exit 2
fi

if [[ ! -f "$profile" ]]; then
  echo "Profile not found: $profile" >&2
  exit 1
fi

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

scalar_value() {
  local section="$1"
  local key="$2"
  awk -v section="$section" -v key="$key" '
    /^[^[:space:]].*:$/ {
      current=$0
      sub(/:.*/, "", current)
    }
    current == section && $0 ~ "^[[:space:]]+" key ":" {
      sub("^[[:space:]]+" key ":[[:space:]]*", "")
      print
      exit
    }
  ' "$profile"
}

list_values() {
  local section="$1"
  local key="${2:-}"
  awk -v section="$section" -v key="$key" '
    /^[^[:space:]].*:$/ {
      current=$0
      sub(/:.*/, "", current)
      in_key=0
      next
    }
    key != "" && current == section && $0 ~ "^[[:space:]]+" key ":" {
      in_key=1
      next
    }
    key == "" && current == section && /^[[:space:]]+-[[:space:]]+/ {
      value=$0
      sub(/^[[:space:]]+-[[:space:]]+/, "", value)
      print value
      next
    }
    key != "" && current == section && in_key && /^[[:space:]]+-[[:space:]]+/ {
      value=$0
      sub(/^[[:space:]]+-[[:space:]]+/, "", value)
      print value
      next
    }
    key != "" && current == section && in_key && /^[[:space:]][^[:space:]-]/ {
      in_key=0
    }
  ' "$profile"
}

project_name="$(trim "$(scalar_value project name)")"
project_domain="$(trim "$(scalar_value project domain)")"
work_queue="$(trim "$(scalar_value agent work_queue)")"
issue_protocol="$(trim "$(scalar_value agent issue_protocol)")"
rules_file="$(trim "$(scalar_value agent rules_file)")"

if [[ -z "$project_name" ]]; then
  echo "Missing required profile field: project.name" >&2
  exit 2
fi

project_domain="${project_domain:-unspecified}"
work_queue="${work_queue:-github-issues}"
issue_protocol="${issue_protocol:-harness/github-issue-protocol.md}"
rules_file="${rules_file:-harness/ai-rules.md}"

stack=()
while IFS= read -r item; do
  stack+=("$item")
done < <(list_values project stack)

constraints=()
while IFS= read -r item; do
  constraints+=("$item")
done < <(list_values constraints)

verification_commands=()
while IFS= read -r item; do
  verification_commands+=("$item")
done < <(list_values verification commands)

agents_file="$output/AGENTS.md"
rules_output="$output/$rules_file"

if [[ -e "$agents_file" && "$force" != true ]]; then
  echo "Refusing to overwrite existing file: $agents_file. Re-run with --force." >&2
  exit 1
fi

if [[ -e "$rules_output" && "$force" != true ]]; then
  echo "Preserving existing file: $rules_output" >&2
else
  mkdir -p "$(dirname "$rules_output")"
  {
    echo "# ai-rules.md"
    echo
    echo "AI와 작업할 때 항상 적용되는 프로젝트별 규칙."
    echo
    echo "## 프로젝트 컨텍스트"
    echo
    echo "- 프로젝트 이름: $project_name"
    echo "- 도메인: $project_domain"
    echo "- 작업 큐: $work_queue"
    echo "- 이슈 프로토콜: $issue_protocol"
    echo
    echo "## 작업 발견 규칙"
    echo
    echo "GitHub Issues가 AI 작업 큐의 정본이다."
    echo "새 작업을 GitHub 이슈로 등록할 때는 \`$issue_protocol\`를 따른다."
    echo
    echo "작업 가능 이슈 쿼리:"
    echo
    echo '```text'
    echo "is:issue is:open label:ai-task label:ready-for-ai -label:needs-clarification -label:blocked"
    echo '```'
    echo
    echo "## 제약"
    echo
    if [[ "${#constraints[@]}" -gt 0 ]]; then
      for item in "${constraints[@]}"; do
        [[ -n "$item" ]] && echo "- $item"
      done
    else
      echo "- 환경변수와 시크릿을 하드코딩하지 않는다."
    fi
  } > "$rules_output"
fi

mkdir -p "$output"
{
  echo "# AGENTS.md"
  echo
  echo "This file defines how AI agents operate in this repository."
  echo
  echo "## Project"
  echo
  echo "- Name: $project_name"
  echo "- Domain: $project_domain"
  echo
  echo "## Stack"
  echo
  if [[ "${#stack[@]}" -gt 0 ]]; then
    for item in "${stack[@]}"; do
      [[ -n "$item" ]] && echo "- $item"
    done
  else
    echo "- unspecified"
  fi
  echo
  echo "## Required Context"
  echo
  echo "- Read \`harness/agent-workflow.md\` first for the end-to-end issue workflow."
  echo "- Read \`$rules_file\` before starting work."
  echo "- Use \`$issue_protocol\` when converting user requests into GitHub issues."
  echo
  echo "## Work Queue"
  echo
  echo "- Source of truth: GitHub Issues."
  echo "- Actionable issues must be open and labeled \`ai-task\` plus \`ready-for-ai\`."
  echo "- Do not work issues labeled \`needs-clarification\` or \`blocked\`."
  echo
  echo "Canonical query:"
  echo
  echo '```text'
  echo "is:issue is:open label:ai-task label:ready-for-ai -label:needs-clarification -label:blocked"
  echo '```'
  echo
  echo "## Constraints"
  echo
  if [[ "${#constraints[@]}" -gt 0 ]]; then
    for item in "${constraints[@]}"; do
      [[ -n "$item" ]] && echo "- $item"
    done
  else
    echo "- Do not hardcode secrets."
  fi
  echo
  echo "## Verification"
  echo
  if [[ "${#verification_commands[@]}" -gt 0 ]]; then
    for item in "${verification_commands[@]}"; do
      [[ -n "$item" ]] && echo "- \`$item\`"
    done
  else
    echo "- Run the smallest relevant test before reporting completion."
  fi
  echo
  echo "## Completion"
  echo
  echo "- Report changed files first."
  echo "- Check results against issue acceptance criteria."
  echo "- Include verification evidence and remaining risks."
} > "$agents_file"

echo "Generated $agents_file"
echo "Generated or preserved $rules_output"
