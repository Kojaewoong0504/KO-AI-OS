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

test_bootstrap_installs_template_and_generates_agents() {
  local target="$tmpdir/target"
  mkdir -p "$target"

  "$repo_root/scripts/bootstrap-ai-os.sh" \
    --profile "$repo_root/tests/fixtures/ai-os.project.yml" \
    --target "$target"

  test -f "$target/.github/ISSUE_TEMPLATE/ai-task.yml"
  test -f "$target/.github/workflows/pre-hook.yml"
  test -f "$target/harness/github-issue-protocol.md"
  test -f "$target/harness/ai-rules.md"
  test -f "$target/memory/mistakes/README.md"
  test -f "$target/scripts/create-ai-issue.sh"
  test -f "$target/scripts/generate-issue-draft.sh"
  test -f "$target/scripts/init-ai-os.sh"
  test -f "$target/scripts/live-smoke-github-issue.sh"
  test -f "$target/scripts/bootstrap-ai-os.sh"
  test -f "$target/scripts/upgrade-ai-os.sh"
  test -f "$target/skills/README.md"
  test -f "$target/templates/agents/AGENTS.md.tpl"
  test -f "$target/docs/github-smoke-test.md"
  test -f "$target/AI_OS_VERSION"
  test -f "$target/AGENTS.md"

  assert_contains "$target/AGENTS.md" "sample-service"
  assert_contains "$target/AGENTS.md" "ready-for-ai"
  assert_contains "$target/harness/ai-rules.md" "sample-service"
}

test_bootstrap_preserves_existing_files_without_force() {
  local target="$tmpdir/preserve"
  mkdir -p "$target/scripts"
  echo "custom script" > "$target/scripts/create-ai-issue.sh"

  "$repo_root/scripts/bootstrap-ai-os.sh" \
    --profile "$repo_root/tests/fixtures/ai-os.project.yml" \
    --target "$target"

  assert_contains "$target/scripts/create-ai-issue.sh" "custom script"
}

test_bootstrap_force_replaces_existing_files() {
  local target="$tmpdir/force"
  mkdir -p "$target/scripts"
  echo "custom script" > "$target/scripts/create-ai-issue.sh"

  "$repo_root/scripts/bootstrap-ai-os.sh" \
    --profile "$repo_root/tests/fixtures/ai-os.project.yml" \
    --target "$target" \
    --force

  assert_contains "$target/scripts/create-ai-issue.sh" "gh issue create"
  if grep -Fq "custom script" "$target/scripts/create-ai-issue.sh"; then
    echo "Expected --force to replace copied script" >&2
    exit 1
  fi
}

test_bootstrap_refuses_existing_agents_without_force() {
  local target="$tmpdir/existing-agents"
  mkdir -p "$target"
  echo "existing agents" > "$target/AGENTS.md"

  if "$repo_root/scripts/bootstrap-ai-os.sh" \
    --profile "$repo_root/tests/fixtures/ai-os.project.yml" \
    --target "$target" >"$tmpdir/existing.out" 2>"$tmpdir/existing.err"; then
    echo "Expected bootstrap to refuse existing AGENTS.md" >&2
    exit 1
  fi

  assert_contains "$tmpdir/existing.err" "Refusing to overwrite"
  assert_contains "$target/AGENTS.md" "existing agents"
}

test_bootstrap_installs_template_and_generates_agents
test_bootstrap_preserves_existing_files_without_force
test_bootstrap_force_replaces_existing_files
test_bootstrap_refuses_existing_agents_without_force

echo "bootstrap ai os tests passed"
