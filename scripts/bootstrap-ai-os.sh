#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: scripts/bootstrap-ai-os.sh --profile ai-os.project.yml --target TARGET_DIR [--force]
USAGE
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

profile=""
target=""
force=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      profile="${2:-}"
      shift 2
      ;;
    --target)
      target="${2:-}"
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

if [[ -z "$profile" || -z "$target" ]]; then
  echo "Missing required option: --profile and --target" >&2
  usage
  exit 2
fi

if [[ ! -f "$profile" ]]; then
  echo "Profile not found: $profile" >&2
  exit 1
fi

mkdir -p "$target"
target="$(cd "$target" && pwd)"

copy_file() {
  local src="$1"
  local dest="$2"

  if [[ -e "$dest" && "$force" != true ]]; then
    echo "Preserving existing file: $dest"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
}

copy_tree() {
  local rel="$1"
  local src_root="$repo_root/$rel"

  if [[ ! -d "$src_root" ]]; then
    return 0
  fi

  while IFS= read -r src; do
    local relative="${src#"$repo_root/"}"

    # ai-rules.md is generated from the target project profile.
    if [[ "$relative" == "harness/ai-rules.md" ]]; then
      continue
    fi

    copy_file "$src" "$target/$relative"
  done < <(find "$src_root" -type f | sort)
}

copy_tree ".github"
copy_tree "harness"
copy_tree "memory"
copy_tree "scripts"
copy_tree "skills"
copy_tree "templates"
copy_tree "docs"
copy_file "$repo_root/ai-os.project.example.yml" "$target/ai-os.project.example.yml"
copy_file "$repo_root/AI_OS_VERSION" "$target/AI_OS_VERSION"

init_args=(
  "$repo_root/scripts/init-ai-os.sh"
  --profile "$profile"
  --output "$target"
)

if [[ "$force" == true ]]; then
  init_args+=(--force)
fi

"${init_args[@]}"

echo "Bootstrapped AI OS into $target"
