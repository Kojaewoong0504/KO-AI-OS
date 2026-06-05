# GitHub Smoke Test

Use this guide after creating a repository from the template or after running `scripts/bootstrap-ai-os.sh` in an existing repository.

## Local Static Check

```bash
scripts/smoke-test-github-setup.sh --repo .
```

Expected result:

```text
github setup smoke test passed
```

This check confirms required workflows, labels, scripts, and harness files exist. It does not call GitHub.

## Live GitHub Check

1. Push the repository to GitHub.
2. Run the `AI OS Label Sync` workflow manually.
3. Create an issue with the `AI 작업` template.
4. Fill `목적`, `수락 기준`, and `범위`.
5. Confirm the pre-hook removes `needs-clarification` and adds `ready-for-ai`.
6. Query ready work:

```text
is:issue is:open label:ai-task label:ready-for-ai -label:needs-clarification -label:blocked
```

Live checks require GitHub Actions permissions and repository issue permissions.
