# GitHub MCP Protocol

GitHub MCP or Connector tools are an alternate transport for the same AI OS issue contract. They do not replace the label, body, or readiness rules.

## Create Issues

When creating an AI task issue through MCP:

- Use the `ai-task` label.
- Render the same sections as `scripts/create-ai-issue.sh`:
  - `목적`
  - `수락 기준`
  - `범위`
  - `제약`
  - `참고 컨텍스트`
  - `예상 결과물`
- Do not add `ready-for-ai` manually. The pre-hook owns readiness.

## Read Ready Work

The ready queue remains:

```text
is:issue is:open label:ai-task label:ready-for-ai -label:needs-clarification -label:blocked
```

Exclude issues labeled `needs-clarification` or `blocked`.

## Complete Work

When reporting through MCP:

- Comment with acceptance-criteria results.
- Include verification evidence.
- Add follow-up issues for new scope instead of expanding the completed issue.
