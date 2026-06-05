#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fakebin="$tmpdir/bin"
mkdir -p "$fakebin"

cat > "$fakebin/gh" <<'FAKE_GH'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >> "$GH_FAKE_LOG"

if [[ "$1 $2" == "issue create" ]]; then
  body_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --body-file)
        body_file="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done
  cp "$body_file" "$GH_FAKE_BODY"
  echo "https://github.com/example/repo/issues/123"
elif [[ "$1 $2" == "issue list" ]]; then
  echo "#123	ready task"
else
  echo "unexpected gh call: $*" >&2
  exit 99
fi
FAKE_GH
chmod +x "$fakebin/gh"

export PATH="$fakebin:$PATH"
export GH_FAKE_LOG="$tmpdir/gh.log"
export GH_FAKE_BODY="$tmpdir/body.md"

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

test_create_ai_issue() {
  "$repo_root/scripts/create-ai-issue.sh" \
    --title "[AI] Add login" \
    --purpose "사용자가 로그인할 수 있게 한다." \
    --criteria "로그인 성공 시 대시보드로 이동한다." \
    --criteria "실패 시 오류 메시지를 보여준다." \
    --scope-include "로그인 폼" \
    --scope-exclude "회원가입" \
    --constraints "기존 인증 API 유지" \
    --context "src/auth" \
    --expected-output "코드 변경" >"$tmpdir/create.out"

  assert_contains "$tmpdir/create.out" "https://github.com/example/repo/issues/123"
  assert_contains "$GH_FAKE_LOG" "issue create"
  assert_contains "$GH_FAKE_LOG" "--label ai-task"
  assert_contains "$GH_FAKE_LOG" "--title [AI] Add login"
  assert_contains "$GH_FAKE_BODY" "## 목적"
  assert_contains "$GH_FAKE_BODY" "사용자가 로그인할 수 있게 한다."
  assert_contains "$GH_FAKE_BODY" "- [ ] 로그인 성공 시 대시보드로 이동한다."
  assert_contains "$GH_FAKE_BODY" "- [ ] 실패 시 오류 메시지를 보여준다."
  assert_contains "$GH_FAKE_BODY" "**포함:**"
  assert_contains "$GH_FAKE_BODY" "- 로그인 폼"
  assert_contains "$GH_FAKE_BODY" "**제외:**"
  assert_contains "$GH_FAKE_BODY" "- 회원가입"
}

test_create_requires_required_fields() {
  if "$repo_root/scripts/create-ai-issue.sh" --title "[AI] Missing" >"$tmpdir/missing.out" 2>"$tmpdir/missing.err"; then
    echo "Expected create-ai-issue.sh to fail with missing fields" >&2
    exit 1
  fi
  assert_contains "$tmpdir/missing.err" "Missing required option"
}

test_create_rejects_empty_required_values() {
  if "$repo_root/scripts/create-ai-issue.sh" \
    --title "[AI] Empty" \
    --purpose "목적" \
    --criteria "" \
    --scope-include "" >"$tmpdir/empty.out" 2>"$tmpdir/empty.err"; then
    echo "Expected create-ai-issue.sh to fail with empty required values" >&2
    exit 1
  fi
  assert_contains "$tmpdir/empty.err" "Missing required option"
}

test_list_ready_ai_issues() {
  "$repo_root/scripts/list-ready-ai-issues.sh" >"$tmpdir/list.out"

  assert_contains "$GH_FAKE_LOG" "issue list"
  assert_contains "$GH_FAKE_LOG" "--label ai-task"
  assert_contains "$GH_FAKE_LOG" "--label ready-for-ai"
  assert_contains "$GH_FAKE_LOG" "--search -label:needs-clarification -label:blocked"
  assert_contains "$tmpdir/list.out" "#123"
}

test_create_ai_issue
test_create_requires_required_fields
test_create_rejects_empty_required_values
test_list_ready_ai_issues

echo "github issue tool tests passed"
