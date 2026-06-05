# Bootstrap AI OS Design

## Purpose

Existing projects need a single command that installs this AI OS template into a target repository and generates project-specific `AGENTS.md` from `ai-os.project.yml`.

## Scope

Included:

- Add `scripts/bootstrap-ai-os.sh`.
- Copy template directories into a target project:
  - `.github/`
  - `harness/`
  - `memory/`
  - `scripts/`
  - `skills/`
  - `templates/`
- Generate `AGENTS.md` and project-specific `harness/ai-rules.md` through `scripts/init-ai-os.sh`.
- Preserve existing files by default.
- Overwrite only when `--force` is passed.
- Verify behavior in temporary target directories.

Excluded:

- Installing GitHub CLI.
- Authenticating GitHub.
- Pushing to GitHub.
- Copying `.git`, `.omx`, or test/docs history into target projects.

## CLI

```bash
scripts/bootstrap-ai-os.sh --profile ai-os.project.yml --target /path/to/project
scripts/bootstrap-ai-os.sh --profile ai-os.project.yml --target /path/to/project --force
```

## Copy Policy

The bootstrap script copies files from the template repository to the target project.

Default behavior:

- Create missing directories.
- Copy missing files.
- Preserve existing files.
- Refuse if `AGENTS.md` already exists, because `init-ai-os.sh` refuses to overwrite it.

Force behavior:

- Replace copied files.
- Re-run `init-ai-os.sh --force`.

Special case:

- `harness/ai-rules.md` is generated from the profile instead of copied as a static template. This keeps the target project-specific.

## Verification

Tests should assert:

- Empty target receives `.github`, `harness`, `memory`, `scripts`, `skills`, `templates`, and `AGENTS.md`.
- Generated `AGENTS.md` contains profile data and `ready-for-ai`.
- Generated `harness/ai-rules.md` contains profile data.
- Existing copied files are preserved without `--force`.
- `--force` replaces existing files.
