# Bootstrap AI OS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a single bootstrap command that installs the AI OS template into an existing project.

**Architecture:** A Bash installer copies template files into a target directory and delegates project-specific instruction generation to `scripts/init-ai-os.sh`.

**Tech Stack:** Bash, shell tests, Markdown documentation.

---

## Tasks

- [ ] Add failing bootstrap tests.
- [ ] Implement `scripts/bootstrap-ai-os.sh`.
- [ ] Update README and verification script.
- [ ] Run all verification and commit.
