# AI OS Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden the AI OS template for real-project use with label sync, smoke checks, easier issue creation, MCP docs, and version metadata.

**Architecture:** Keep the template shell-first. Add static workflows/docs and extend the existing fake-`gh` tests to cover file-based issue drafts.

**Tech Stack:** Bash, GitHub Actions, Markdown, shell tests.

---

## Tasks

- [x] Add failing tests for labels, smoke checks, file-based issue creation, and bootstrap version copying.
- [x] Add label definitions and label sync workflow.
- [x] Extend `create-ai-issue.sh` with `--from-file`.
- [x] Add smoke-test script and GitHub smoke test guide.
- [x] Add MCP protocol docs and version metadata.
- [x] Update bootstrap, README, and verifier.
- [x] Run all verification and commit.
