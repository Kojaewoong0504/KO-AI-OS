#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

assert_contains() {
  local file="$1"
  local expected="$2"
  if ! grep -Fq -- "$expected" "$file"; then
    echo "Expected '$expected' in $file" >&2
    echo "--- $file ---" >&2
    cat "$file" >&2
    exit 1
  fi
}

assert_not_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    echo "Expected path not to exist: $path" >&2
    find "$path" -maxdepth 3 -print >&2 2>/dev/null || true
    exit 1
  fi
}

test_gitignore_excludes_local_template_artifacts() {
  test -f "$repo_root/.gitignore"
  assert_contains "$repo_root/.gitignore" ".omx/"
  assert_contains "$repo_root/.gitignore" "docs/superpowers/"
  assert_contains "$repo_root/.gitignore" "ai-os.project.yml"
  assert_contains "$repo_root/.gitignore" "issue.yml"
}

test_generate_issue_draft() {
  local draft="$tmpdir/issue.yml"

  "$repo_root/scripts/generate-issue-draft.sh" \
    --title "[AI] Draft task" \
    --purpose "대화 내용을 이슈 초안으로 저장한다." \
    --criteria "초안 파일이 생성된다." \
    --scope-include "scripts/generate-issue-draft.sh" \
    --scope-exclude "GitHub API 호출" \
    --constraints "기존 create-ai-issue.sh 형식 유지" \
    --context "harness/github-issue-protocol.md" \
    --expected-output "issue.yml" \
    --output "$draft"

  assert_contains "$draft" 'title: "[AI] Draft task"'
  assert_contains "$draft" 'purpose: "대화 내용을 이슈 초안으로 저장한다."'
  assert_contains "$draft" 'criteria:'
  assert_contains "$draft" '  - "초안 파일이 생성된다."'
  assert_contains "$draft" 'scope_include:'
  assert_contains "$draft" '  - "scripts/generate-issue-draft.sh"'
}

test_upgrade_preserves_existing_files_and_copies_version() {
  local target="$tmpdir/upgrade"
  mkdir -p "$target/scripts"
  echo "old version" > "$target/AI_OS_VERSION"
  echo "custom script" > "$target/scripts/create-ai-issue.sh"

  "$repo_root/scripts/upgrade-ai-os.sh" \
    --target "$target" >"$tmpdir/upgrade.out"

  assert_contains "$target/scripts/create-ai-issue.sh" "custom script"
  assert_contains "$target/AI_OS_VERSION" "0.1.0"
  assert_contains "$tmpdir/upgrade.out" "Upgraded AI OS"
}

test_upgrade_force_replaces_existing_files() {
  local target="$tmpdir/upgrade-force"
  mkdir -p "$target/scripts"
  echo "custom script" > "$target/scripts/create-ai-issue.sh"

  "$repo_root/scripts/upgrade-ai-os.sh" \
    --target "$target" \
    --force >"$tmpdir/upgrade-force.out"

  assert_contains "$target/scripts/create-ai-issue.sh" "gh issue create"
}

test_bootstrap_does_not_copy_internal_superpowers_docs() {
  local target="$tmpdir/bootstrap"
  mkdir -p "$target"

  "$repo_root/scripts/bootstrap-ai-os.sh" \
    --profile "$repo_root/tests/fixtures/ai-os.project.yml" \
    --target "$target" >"$tmpdir/bootstrap.out"

  test -f "$target/docs/github-smoke-test.md"
  assert_not_exists "$target/docs/superpowers"
}

test_gitignore_excludes_local_template_artifacts
test_generate_issue_draft
test_upgrade_preserves_existing_files_and_copies_version
test_upgrade_force_replaces_existing_files
test_bootstrap_does_not_copy_internal_superpowers_docs

echo "productization tests passed"
