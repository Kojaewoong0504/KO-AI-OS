# GitHub Issue Work Queue Design

## Purpose

This template must let an AI agent understand what work is ready in any repository created from it. GitHub Issues are the source of truth. A task becomes actionable only when the repository automation marks it as ready.

## Scope

Included:

- Define GitHub Issues as the canonical AI work queue.
- Use labels to distinguish draft, blocked, and actionable AI tasks.
- Update the issue pre-hook behavior so successful linting adds `ready-for-ai`.
- Document the agent-facing work discovery protocol.
- Keep the design independent of a specific AI tool, CLI, or GitHub account.

Excluded:

- Implementing a full GitHub API client.
- Automatically assigning issues to a specific human or bot account.
- Opening pull requests or committing code from GitHub Actions.
- Replacing the existing `ai-task` issue template.

## Work Queue Model

The canonical work queue is:

```text
open GitHub Issues with labels: ai-task + ready-for-ai
```

The agent must not treat an issue as actionable when it has any of these states:

- Closed.
- Missing `ai-task`.
- Missing `ready-for-ai`.
- Has `needs-clarification`.
- Has `blocked`.

`ready-for-ai` is an explicit readiness signal, not an inferred absence of problems. This avoids ambiguity when an issue has been edited, partially completed, or temporarily blocked.

## Label Contract

| Label | Meaning | Owner |
| --- | --- | --- |
| `ai-task` | This issue is intended for AI-assisted work. | Issue creator or template |
| `ready-for-ai` | The issue passed required pre-hook checks and can be selected by an agent. | GitHub Actions pre-hook |
| `needs-clarification` | Required issue fields are missing or invalid. | GitHub Actions pre-hook |
| `blocked` | The issue cannot progress without external input or dependency resolution. | Human or agent |

## State Transitions

When an `ai-task` issue is opened or edited:

1. The pre-hook checks required sections:
   - `목적`
   - `수락 기준`
   - `범위`
2. If validation fails:
   - Add `needs-clarification`.
   - Remove `ready-for-ai` if present.
   - Comment with missing fields.
   - Fail the workflow.
3. If validation passes:
   - Remove `needs-clarification` if present.
   - Add `ready-for-ai`.
   - Comment that the issue is ready for AI work.

When an issue is closed:

1. The post-hook adds the existing completion checklist.
2. The issue leaves the work queue because it is no longer open.

## Agent Work Discovery Protocol

An agent operating inside a repository created from this template should follow this protocol before choosing a task:

1. Load the repository instructions from `AGENTS.md` when present, then `harness/ai-rules.md`.
2. Query open GitHub Issues labeled `ai-task` and `ready-for-ai`.
3. Exclude any issue labeled `needs-clarification` or `blocked`.
4. Prefer the oldest ready issue unless the user names a specific issue or priority label.
5. Read the issue body and comments before editing code.
6. Treat issue acceptance criteria as the completion contract.
7. Report completion against the acceptance criteria and verification evidence.

This protocol should be documented in the template so any agent can discover it without knowing project-specific conventions.

## Repository Changes Needed

The implementation should update:

- `.github/workflows/pre-hook.yml`
  - Add `ready-for-ai` on successful validation.
  - Remove `ready-for-ai` on failed validation.
  - Keep existing `needs-clarification` behavior.
- `harness/ai-rules.md`
  - Add a work discovery section for agents.
  - Define the label contract and actionable issue query.
- `README.md`
  - Explain the GitHub Issue work queue flow for users of the template.

Optional, if useful during implementation:

- Add `harness/work-queue.md` if the work discovery protocol becomes too large for `ai-rules.md`.

## Error Handling

The pre-hook should tolerate missing labels during removal. A missing `ready-for-ai` or `needs-clarification` label should not fail the success or failure path.

If label creation is not automatic in the repository, GitHub will create labels when Actions adds them. The workflow should continue using `issues: write` permission.

## Testing

Verification should cover:

- A complete `ai-task` issue receives `ready-for-ai`.
- An incomplete `ai-task` issue receives `needs-clarification`.
- An incomplete issue does not keep stale `ready-for-ai`.
- Existing post-hook behavior remains unchanged.
- Documentation clearly states the work queue query:

```text
is:issue is:open label:ai-task label:ready-for-ai -label:needs-clarification -label:blocked
```

## Open Decisions

No unresolved product decisions remain for the first implementation pass.

Future extensions may add priority labels, assignment rules, stale issue handling, or a CLI helper for querying the work queue.
