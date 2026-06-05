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

test_label_contract_files_exist() {
  test -f "$repo_root/.github/labels.yml"
  test -f "$repo_root/.github/workflows/label-sync.yml"

  assert_contains "$repo_root/.github/labels.yml" "name: ai-task"
  assert_contains "$repo_root/.github/labels.yml" "name: ready-for-ai"
  assert_contains "$repo_root/.github/labels.yml" "name: needs-clarification"
  assert_contains "$repo_root/.github/labels.yml" "name: blocked"
  assert_contains "$repo_root/.github/workflows/label-sync.yml" "upsert-labels"
}

test_smoke_test_files_exist_and_pass() {
  test -f "$repo_root/docs/github-smoke-test.md"
  test -x "$repo_root/scripts/smoke-test-github-setup.sh"
  test -x "$repo_root/scripts/live-smoke-github-issue.sh"

  "$repo_root/scripts/smoke-test-github-setup.sh" --repo "$repo_root" >"$tmpdir/smoke.out"
  assert_contains "$tmpdir/smoke.out" "github setup smoke test passed"
}

test_version_metadata_exists() {
  test -f "$repo_root/AI_OS_VERSION"
  assert_contains "$repo_root/AI_OS_VERSION" "0.1.0"
}

test_mcp_protocol_exists() {
  test -f "$repo_root/harness/github-mcp-protocol.md"
  assert_contains "$repo_root/harness/github-mcp-protocol.md" "ai-task"
  assert_contains "$repo_root/harness/github-mcp-protocol.md" "ready-for-ai"
}

test_bootstrap_copies_version_metadata() {
  local target="$tmpdir/bootstrap"
  mkdir -p "$target"

  "$repo_root/scripts/bootstrap-ai-os.sh" \
    --profile "$repo_root/tests/fixtures/ai-os.project.yml" \
    --target "$target" >"$tmpdir/bootstrap.out"

  test -f "$target/AI_OS_VERSION"
  assert_contains "$target/AI_OS_VERSION" "0.1.0"
}

test_label_contract_files_exist
test_smoke_test_files_exist_and_pass
test_version_metadata_exists
test_mcp_protocol_exists
test_bootstrap_copies_version_metadata

echo "hardening tests passed"
