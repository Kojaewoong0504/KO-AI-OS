# GitHub Issue Work Queue Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make GitHub Issues with `ai-task` and `ready-for-ai` the explicit work queue for repositories created from this template.

**Architecture:** The existing GitHub Actions pre-hook remains the readiness gate. It adds or removes labels based on issue completeness, while repository docs teach agents how to query the queue and interpret labels.

**Tech Stack:** GitHub Actions, `actions/github-script@v7`, Markdown documentation, shell-based static verification.

---

## File Structure

- Modify `.github/workflows/pre-hook.yml`
  - Adds `ready-for-ai` when an `ai-task` issue passes validation.
  - Removes `ready-for-ai` when validation fails.
  - Keeps existing `needs-clarification` behavior.
- Modify `harness/ai-rules.md`
  - Adds the agent work discovery protocol.
  - Defines the actionable issue query and label contract.
- Modify `README.md`
  - Explains the GitHub Issue work queue flow for template users.
- Create `scripts/verify-work-queue.sh`
  - Runs lightweight static checks that lock the label contract and documentation query.

## Task 1: Add Work Queue Verification

**Files:**
- Create: `scripts/verify-work-queue.sh`

- [x] **Step 1: Create the verification script**

```bash
#!/usr/bin/env bash
set -euo pipefail

pre_hook=".github/workflows/pre-hook.yml"
rules="harness/ai-rules.md"
readme="README.md"

grep -q "labels: \\['ready-for-ai'\\]" "$pre_hook"
grep -q "name: 'ready-for-ai'" "$pre_hook"
grep -q "labels: \\['needs-clarification'\\]" "$pre_hook"

grep -q "is:issue is:open label:ai-task label:ready-for-ai -label:needs-clarification -label:blocked" "$rules"
grep -q "ready-for-ai" "$readme"

echo "work queue verification passed"
```

- [x] **Step 2: Run script before implementation to verify it fails**

Run: `bash scripts/verify-work-queue.sh`

Expected: FAIL because the script does not exist yet or because `ready-for-ai` is not implemented in the workflow/docs.

- [x] **Step 3: Commit verification script after implementation**

```bash
git add scripts/verify-work-queue.sh
git commit -m "Verify the issue work queue contract" -m "Constraint: The template has no app test runner, so static checks lock the GitHub Actions and documentation contract
Rejected: Leaving readiness behavior untested | label regressions would be easy to miss in a YAML-only change
Confidence: high
Scope-risk: narrow
Directive: Update this verifier whenever the canonical work queue query changes
Tested: bash scripts/verify-work-queue.sh
Not-tested: Live GitHub Actions execution"
```

## Task 2: Implement Pre-Hook Label Transitions

**Files:**
- Modify: `.github/workflows/pre-hook.yml`

- [x] **Step 1: Update failure path**

Add removal of stale `ready-for-ai` before failing validation:

```js
try {
  await github.rest.issues.removeLabel({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: issueNumber,
    name: 'ready-for-ai',
  });
} catch (e) {}
```

- [x] **Step 2: Update success path**

Add `ready-for-ai` after removing `needs-clarification`:

```js
await github.rest.issues.addLabels({
  owner: context.repo.owner,
  repo: context.repo.repo,
  issue_number: issueNumber,
  labels: ['ready-for-ai'],
});
```

Update the success comment so it names the readiness label:

```js
'- [x] ready-for-ai 라벨 부여',
```

- [x] **Step 3: Run verification**

Run: `bash scripts/verify-work-queue.sh`

Expected: PASS after Task 3 documentation is also complete.

## Task 3: Document Agent Work Discovery

**Files:**
- Modify: `harness/ai-rules.md`
- Modify: `README.md`

- [x] **Step 1: Add work discovery to `harness/ai-rules.md`**

Add a section before `작업 전 규칙`:

~~~markdown
## 작업 발견 규칙

GitHub Issues가 AI 작업 큐의 정본이다.

작업 가능 이슈 쿼리:

```text
is:issue is:open label:ai-task label:ready-for-ai -label:needs-clarification -label:blocked
```

- `ai-task`: AI가 처리할 수 있는 작업
- `ready-for-ai`: pre-hook을 통과해 작업 가능한 상태
- `needs-clarification`: 목적·수락 기준·범위가 부족해 작업 금지
- `blocked`: 외부 입력이나 의존성 때문에 작업 금지

작업 시작 전에는 가장 오래된 `ready-for-ai` 이슈를 우선 확인한다.
사용자가 특정 이슈 번호나 우선순위를 지정하면 그 지시를 우선한다.
이슈 본문과 코멘트를 읽고, 수락 기준을 완료 계약으로 삼는다.
~~~

- [x] **Step 2: Update `README.md` pre-hook section**

Document that complete issues receive `ready-for-ai`, incomplete issues receive `needs-clarification`, and agents should query:

```text
is:issue is:open label:ai-task label:ready-for-ai -label:needs-clarification -label:blocked
```

- [x] **Step 3: Run verification**

Run: `bash scripts/verify-work-queue.sh`

Expected: `work queue verification passed`

- [x] **Step 4: Commit implementation and docs**

```bash
git add .github/workflows/pre-hook.yml harness/ai-rules.md README.md scripts/verify-work-queue.sh
git commit -m "Expose ready AI issues as the work queue" -m "Constraint: GitHub Issues are the canonical queue for template-derived repositories
Rejected: Treating every ai-task issue as actionable | incomplete issues need an explicit non-ready state
Confidence: high
Scope-risk: narrow
Directive: Agents should query ai-task plus ready-for-ai and exclude needs-clarification or blocked
Tested: bash scripts/verify-work-queue.sh
Not-tested: Live GitHub Actions execution against a remote repository"
```
