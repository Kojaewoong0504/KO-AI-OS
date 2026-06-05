# GitHub Issue Tools Design

## Purpose

Repositories created from this template need a concrete way for an agent conversation to create and inspect GitHub AI task issues. The first implementation should work without a custom MCP server by using the GitHub CLI.

## Scope

Included:

- Create `ai-task` GitHub issues from structured conversation output.
- List open `ai-task + ready-for-ai` issues.
- Document the agent protocol for turning a user request into an issue body.
- Verify the shell tools without making network calls.

Excluded:

- A custom MCP server.
- Direct GitHub REST API token handling.
- Automatically editing code after issue creation.
- Live GitHub integration tests.

## Approach

Use `gh` CLI as the default transport. It already handles authentication, repository detection, and GitHub API calls. Agents can call the scripts directly when `gh auth status` succeeds.

MCP remains optional. If a runtime exposes GitHub MCP/Connector tools, the agent can use those tools instead of the scripts while preserving the same issue body format, labels, and readiness protocol.

## Tools

- `scripts/create-ai-issue.sh`
  - Accepts title, purpose, acceptance criteria, scope, constraints, context, and expected output.
  - Renders the existing `ai-task` issue body shape.
  - Calls `gh issue create --label ai-task --title ... --body-file ...`.
- `scripts/list-ready-ai-issues.sh`
  - Calls `gh issue list` with the canonical ready queue labels and search query.
- `harness/github-issue-protocol.md`
  - Tells agents how to convert a conversation into an issue.

## Success Criteria

- Scripts fail clearly when `gh` is missing.
- Issue creation requires non-empty title, purpose, acceptance criteria, and scope.
- Tests verify generated `gh` calls and issue body contents with a fake `gh`.
- Documentation explains when MCP is useful and why it is not required for the MVP.
