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

test_generates_agents_and_harness_files() {
  local output="$tmpdir/generated"
  mkdir -p "$output"

  "$repo_root/scripts/init-ai-os.sh" \
    --profile "$repo_root/tests/fixtures/ai-os.project.yml" \
    --output "$output"

  test -f "$output/AGENTS.md"
  test -f "$output/harness/ai-rules.md"

  assert_contains "$output/AGENTS.md" "sample-service"
  assert_contains "$output/AGENTS.md" "SaaS backend"
  assert_contains "$output/AGENTS.md" "Python"
  assert_contains "$output/AGENTS.md" "harness/ai-rules.md"
  assert_contains "$output/AGENTS.md" "harness/github-issue-protocol.md"
  assert_contains "$output/AGENTS.md" "ready-for-ai"
  assert_contains "$output/AGENTS.md" "Never hardcode secrets"
  assert_contains "$output/AGENTS.md" "pytest"
  assert_contains "$output/AGENTS.md" "npm test"
  assert_contains "$output/harness/ai-rules.md" "sample-service"
  assert_contains "$output/harness/ai-rules.md" "harness/github-issue-protocol.md"
}

test_refuses_to_overwrite_agents_without_force() {
  local output="$tmpdir/existing"
  mkdir -p "$output"
  echo "existing agents" > "$output/AGENTS.md"

  if "$repo_root/scripts/init-ai-os.sh" \
    --profile "$repo_root/tests/fixtures/ai-os.project.yml" \
    --output "$output" >"$tmpdir/overwrite.out" 2>"$tmpdir/overwrite.err"; then
    echo "Expected init-ai-os.sh to refuse overwriting AGENTS.md" >&2
    exit 1
  fi

  assert_contains "$tmpdir/overwrite.err" "Refusing to overwrite"
  assert_contains "$output/AGENTS.md" "existing agents"
}

test_force_overwrites_agents() {
  local output="$tmpdir/force"
  mkdir -p "$output"
  echo "existing agents" > "$output/AGENTS.md"

  "$repo_root/scripts/init-ai-os.sh" \
    --profile "$repo_root/tests/fixtures/ai-os.project.yml" \
    --output "$output" \
    --force

  assert_contains "$output/AGENTS.md" "sample-service"
  if grep -Fq "existing agents" "$output/AGENTS.md"; then
    echo "Expected --force to replace AGENTS.md" >&2
    exit 1
  fi
}

test_generates_agents_and_harness_files
test_refuses_to_overwrite_agents_without_force
test_force_overwrites_agents

echo "ai os init tests passed"
