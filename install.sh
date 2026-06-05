#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  ./install.sh [--target DIR] [--name NAME] [--domain DOMAIN] [--stack ITEM] [--verify CMD] [--constraint TEXT] [--force]

Remote:
  curl -fsSL https://raw.githubusercontent.com/Kojaewoong0504/KO-AI-OS/main/install.sh \
    | bash -s -- --target . --name my-project --domain "SaaS backend"

Options:
  --target DIR      Project directory to install into. Defaults to current directory.
  --profile FILE    Existing ai-os.project.yml to use.
  --name NAME       Project name. Defaults to target directory name.
  --domain DOMAIN   Project domain. Defaults to unspecified.
  --stack ITEM      Stack item. Can be repeated.
  --verify CMD      Verification command. Can be repeated.
  --constraint TEXT Project constraint. Can be repeated.
  --force           Overwrite existing install files where supported.
  --repo-url URL    Template repository URL. Defaults to this repository.
  --ref REF         Git ref to install from when cloning. Defaults to main.
USAGE
}

quote_yaml() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '"%s"' "$value"
}

target="."
profile=""
project_name=""
domain="unspecified"
force=false
repo_url="https://github.com/Kojaewoong0504/KO-AI-OS.git"
ref="main"
stack=()
verification=()
constraints=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      target="${2:-}"
      shift 2
      ;;
    --profile)
      profile="${2:-}"
      shift 2
      ;;
    --name)
      project_name="${2:-}"
      shift 2
      ;;
    --domain)
      domain="${2:-}"
      shift 2
      ;;
    --stack)
      stack+=("${2:-}")
      shift 2
      ;;
    --verify)
      verification+=("${2:-}")
      shift 2
      ;;
    --constraint)
      constraints+=("${2:-}")
      shift 2
      ;;
    --force)
      force=true
      shift
      ;;
    --repo-url)
      repo_url="${2:-}"
      shift 2
      ;;
    --ref)
      ref="${2:-}"
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

mkdir -p "$target"
target="$(cd "$target" && pwd)"

script_path="${BASH_SOURCE[0]:-}"
repo_root=""
tmpdir=""

if [[ -n "$script_path" && -f "$script_path" ]]; then
  candidate_root="$(cd "$(dirname "$script_path")" && pwd)"
  if [[ -x "$candidate_root/scripts/bootstrap-ai-os.sh" ]]; then
    repo_root="$candidate_root"
  fi
fi

if [[ -z "$repo_root" ]]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "Missing required command: git. Install git or clone the template repository first." >&2
    exit 127
  fi
  tmpdir="$(mktemp -d)"
  trap '[[ -n "$tmpdir" ]] && rm -rf "$tmpdir"' EXIT
  git clone --depth 1 --branch "$ref" "$repo_url" "$tmpdir/ai-os" >/dev/null
  repo_root="$tmpdir/ai-os"
fi

if [[ -n "$profile" ]]; then
  if [[ ! -f "$profile" ]]; then
    echo "Profile not found: $profile" >&2
    exit 1
  fi
elif [[ -f "$target/ai-os.project.yml" ]]; then
  profile="$target/ai-os.project.yml"
else
  profile="$target/ai-os.project.yml"
  project_name="${project_name:-$(basename "$target")}"

  if [[ "${#stack[@]}" -eq 0 ]]; then
    stack+=("unspecified")
  fi
  if [[ "${#constraints[@]}" -eq 0 ]]; then
    constraints+=("Never hardcode secrets")
  fi
  if [[ "${#verification[@]}" -eq 0 ]]; then
    verification+=("scripts/smoke-test-github-setup.sh --repo .")
  fi

  {
    echo "project:"
    printf '  name: '
    quote_yaml "$project_name"
    printf '\n'
    printf '  domain: '
    quote_yaml "$domain"
    printf '\n'
    echo "  stack:"
    for item in "${stack[@]}"; do
      printf '    - '
      quote_yaml "$item"
      printf '\n'
    done
    echo
    echo "agent:"
    echo "  work_queue: github-issues"
    echo "  issue_protocol: harness/github-issue-protocol.md"
    echo "  rules_file: harness/ai-rules.md"
    echo
    echo "constraints:"
    for item in "${constraints[@]}"; do
      printf '  - '
      quote_yaml "$item"
      printf '\n'
    done
    echo
    echo "verification:"
    echo "  commands:"
    for item in "${verification[@]}"; do
      printf '    - '
      quote_yaml "$item"
      printf '\n'
    done
  } > "$profile"
fi

args=(
  "$repo_root/scripts/bootstrap-ai-os.sh"
  --profile "$profile"
  --target "$target"
)

if [[ "$force" == true ]]; then
  args+=(--force)
fi

"${args[@]}"

echo
echo "AI OS install complete."
echo "Target: $target"
echo "Profile: $profile"
echo
echo "Next:"
echo "  cd \"$target\""
echo "  scripts/smoke-test-github-setup.sh --repo ."
