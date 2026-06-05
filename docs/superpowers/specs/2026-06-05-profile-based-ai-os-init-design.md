# Profile Based AI OS Init Design

## Purpose

Projects created from this template need an easy way to generate `AGENTS.md` and related AI operating files from structured project metadata. The source of truth for generation is a repository-local profile file.

## Scope

Included:

- Define `ai-os.project.yml` as the project profile input.
- Generate `AGENTS.md` from that profile.
- Generate or preserve `harness/ai-rules.md`.
- Link generated instructions to the GitHub issue work queue and `harness/github-issue-protocol.md`.
- Refuse to overwrite existing generated files unless `--force` is passed.
- Verify generation in a temporary output directory.

Excluded:

- Full YAML support.
- Interactive prompts.
- Custom per-agent prompt systems beyond templates.
- Automatically installing dependencies.

## Profile Contract

The MVP supports a small YAML subset:

```yaml
project:
  name: my-service
  domain: SaaS backend
  stack:
    - Python
    - FastAPI

agent:
  work_queue: github-issues
  issue_protocol: harness/github-issue-protocol.md
  rules_file: harness/ai-rules.md

constraints:
  - Never hardcode secrets

verification:
  commands:
    - pytest
```

Only the fields above are guaranteed. Unknown fields are ignored.

## Generated Files

- `AGENTS.md`
  - Project identity.
  - Required context files.
  - GitHub issue work queue rules.
  - Constraints.
  - Verification commands.
  - Completion reporting rules.
- `harness/ai-rules.md`
  - Created from a template if missing.
  - Preserved unless `--force` is passed.

The generator may later add `CLAUDE.md` and `GEMINI.md`, but they are not required for the first pass.

## CLI

```bash
scripts/init-ai-os.sh --profile ai-os.project.yml --output .
scripts/init-ai-os.sh --profile ai-os.project.yml --output . --force
```

`--output` lets tests and agents generate into a target project directory without mutating the template repository.

## Error Handling

- Missing profile fails with a clear message.
- Missing required project name fails.
- Existing `AGENTS.md` fails unless `--force` is passed.
- Existing `harness/ai-rules.md` is preserved unless `--force` is passed.

## Verification

Tests should generate into a temporary project directory and assert:

- `AGENTS.md` exists.
- `AGENTS.md` names `harness/ai-rules.md`.
- `AGENTS.md` names `harness/github-issue-protocol.md`.
- `AGENTS.md` includes `ready-for-ai`.
- Verification commands from the profile appear.
- Existing `AGENTS.md` is not overwritten without `--force`.
