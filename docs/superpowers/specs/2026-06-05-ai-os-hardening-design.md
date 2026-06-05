# AI OS Hardening Design

## Purpose

The template now has a usable MVP. The next pass should make it safer and easier to operate across real repositories by standardizing labels, adding smoke-test guidance, improving issue creation UX, documenting MCP usage, and adding basic version metadata.

## Scope

Included:

- Add canonical GitHub label definitions.
- Add a label sync workflow.
- Add a local smoke-test guide/script for checking the issue workflow setup.
- Add file-based input to `scripts/create-ai-issue.sh` so agents and humans can pass an issue draft file instead of many CLI flags.
- Add GitHub MCP/Connector usage documentation.
- Add template version metadata and copy it during bootstrap.

Excluded:

- Live GitHub API tests in CI.
- A custom MCP server.
- Automatic token or credential setup.
- Complex YAML parsing beyond the supported profile/issue draft subset.

## Design

### Labels

Add `.github/labels.yml` as the canonical label list:

- `ai-task`
- `ready-for-ai`
- `needs-clarification`
- `blocked`

Add `.github/workflows/label-sync.yml` using `actions/github-script` to upsert those labels on manual dispatch and changes to `.github/labels.yml`.

### Smoke Test

Add `docs/github-smoke-test.md` and `scripts/smoke-test-github-setup.sh`.

The script performs local static checks only:

- Required workflows exist.
- Required labels are declared.
- Required scripts exist.
- `gh` availability/auth status is reported as diagnostic information, not required for local verification.

### Issue Creation UX

`scripts/create-ai-issue.sh` should accept:

```bash
scripts/create-ai-issue.sh --from-file issue.yml
```

The supported issue draft fields are:

```yaml
title: "[AI] Add login"
purpose: "사용자가 로그인할 수 있게 한다."
criteria:
  - "로그인 성공 시 대시보드로 이동한다."
scope_include:
  - "로그인 폼"
scope_exclude:
  - "회원가입"
constraints: "기존 인증 API 유지"
context: "src/auth"
expected_output: "코드 변경"
```

CLI flags remain supported and override file values when both are present.

### MCP Documentation

Add `harness/github-mcp-protocol.md` explaining that MCP is an alternate transport for the same issue contract:

- Use `ai-task` when creating issues.
- Read ready issues using `ai-task + ready-for-ai`.
- Do not bypass the issue body contract.

### Versioning

Add `AI_OS_VERSION` with a simple version string. Bootstrap copies it into target projects so future upgrade scripts can compare installed versions.

## Verification

Tests should verify:

- Label files and workflow include required labels.
- `create-ai-issue.sh --from-file` renders the same issue body as CLI flags.
- Smoke-test script passes locally.
- Bootstrap copies `AI_OS_VERSION`.
- Existing test suites still pass.
