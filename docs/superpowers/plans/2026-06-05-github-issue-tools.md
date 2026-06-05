# GitHub Issue Tools Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `gh` CLI scripts that let agents create AI task issues and list the ready work queue.

**Architecture:** Shell scripts provide the stable local interface. Tests use temporary fake `gh` executables so verification never touches GitHub.

**Tech Stack:** Bash, GitHub CLI, Markdown, shell test scripts.

---

## Tasks

- [x] Add failing shell tests for issue creation and ready issue listing.
- [x] Implement `scripts/create-ai-issue.sh`.
- [x] Implement `scripts/list-ready-ai-issues.sh`.
- [x] Add `harness/github-issue-protocol.md`.
- [x] Update README and verification script.
- [x] Run all verification and commit.
