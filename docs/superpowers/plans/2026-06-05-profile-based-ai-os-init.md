# Profile Based AI OS Init Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate `AGENTS.md` and AI OS harness files from `ai-os.project.yml`.

**Architecture:** A Bash generator parses the supported profile subset and renders Markdown files. Shell tests use fixture profiles and temporary output directories.

**Tech Stack:** Bash, Markdown templates, shell tests.

---

## Tasks

- [ ] Add profile fixture and failing init tests.
- [ ] Implement `scripts/init-ai-os.sh`.
- [ ] Add template files under `templates/agents/`.
- [ ] Add `ai-os.project.example.yml`.
- [ ] Update README and verification script.
- [ ] Run all verification and commit.
