---
layout: default
title: "10X Developer Unicorn — Claude Code Plugin for AI Agent Orchestration"
description: "The best Claude Code plugin for professional software engineering. 5 AI agents (architect, developer, QA, DevOps, polyglot) and 13 skills enforce TDD, code review, security audits, and estimation automatically."
image: /assets/images/hero.png
hero: true
hero_image: "assets/images/hero.png"
hero_title: "10X Developer Unicorn"
hero_tagline: "A Claude Code plugin that transforms your AI assistant into a coordinated engineering team. 5 agents. 13 skills. The hidden 80% of software engineering -- encoded."
hero_actions:
  - label: "Get Started"
    url: "/unicorn-team/getting-started/"
    style: "btn-primary"
  - label: "View on GitHub"
    url: "https://github.com/aj-geddes/unicorn-team"
    style: "btn-secondary"
hero_stats:
  - number: "5"
    label: "Agents"
    color: "var(--blue)"
  - number: "13"
    label: "Skills"
    color: "var(--mauve)"
  - number: "110"
    label: "Tests Passing"
    color: "var(--green)"
  - number: "58"
    label: "Reference Docs"
    color: "var(--peach)"
permalink: /
---

## What Is This?

<img src="{{ site.baseurl }}/assets/images/concept.png" alt="The Hidden 80% — most AI tools cover the visible 20% of software engineering, unicorn-team encodes the hidden 80% with 5 agents and 13 skills" class="concept-image">

Most AI coding tools help with the **visible 20%** of software engineering: writing code. But professional developers spend 80% of their time on everything *around* the code -- reading existing systems, recognizing patterns, estimating effort, reviewing their own work, managing technical debt, thinking about security.

**10X Developer Unicorn** is a Claude Code plugin that encodes that hidden 80%. It transforms Claude Code from a single AI assistant into a **coordinated team of 5 specialized agents** with 13 composable skills that mirror how senior engineers actually work.

The result: Claude Code that doesn't just write code -- it reads codebases strategically, enforces TDD discipline, self-reviews before committing, estimates with risk buffers, and manages technical debt deliberately.

---

## Install

```bash
# Add the marketplace
claude plugin marketplace add aj-geddes/unicorn-team

# Install the plugin
claude plugin install unicorn-team@unicorn-team
```

That's it. Skills are discovered automatically. Hooks are wired. The orchestrator activates.

<img src="{{ site.baseurl }}/assets/images/install-process.png" alt="Terminal showing unicorn-team plugin installation — 13 skills loaded, 5 agents ready, orchestrator activated" class="concept-image">

---

## How It Works

The orchestrator analyzes every task and routes it to the right specialist. Each agent gets a fresh 200K context window, so you never run out of room.

<img src="{{ site.baseurl }}/assets/images/core-workflow.png" alt="Core workflow — User Request flows through Orchestrator to Agent Team (Architect, Developer, QA-Security, DevOps, Polyglot), through Quality Gates, to Result + Proof" class="concept-image">

---

## Agents + Skills

### 5 Specialized Agents

Each agent runs in its own 200K context window with protocol content inlined directly -- no duplicate slash commands.

| Agent | What It Does |
|-------|-------------|
| **architect** | System design, ADRs, API contracts, tradeoff analysis |
| **developer** | TDD-first implementation across Python, JS/TS, Go, Rust |
| **qa-security** | Code review, security audits, OWASP analysis, quality gates |
| **devops** | CI/CD pipelines, Kubernetes, Terraform, deployment strategies |
| **polyglot** | Rapid language acquisition, cross-ecosystem migration |

### 13 Composable Skills

#### Coordination

| Skill | What It Does |
|-------|-------------|
| **orchestrator** | Routes tasks, coordinates agents, enforces quality gates |

#### Meta Skills

These encode the "hidden 80%" -- the engineering judgment skills that separate senior developers from code generators.

| Skill | What It Does |
|-------|-------------|
| **code-reading** | Strategic codebase comprehension: entry points, data flow, impact analysis |
| **pattern-transfer** | Recognizes problem classes, transfers solutions across languages and domains |
| **self-verification** | Pre-commit self-review protocol: catches issues before they reach code review |
| **estimation** | Risk-based estimation with PERT formula, decomposition, and confidence levels |
| **technical-debt** | Deliberate debt tracking, classification, prioritization, and paydown planning |
| **language-learning** | Structured 5-phase protocol for rapid paradigm and language acquisition |
| **hvs-skill-buddy** | Meta-skill for auditing, creating, and maintaining skills |

### Domain Skills

Language-specific idioms, tooling, and patterns that agents draw on during execution.

| Skill | What It Does |
|-------|-------------|
| **python** | Modern Python idioms, pytest patterns, ruff/mypy tooling, project structure |
| **javascript** | TypeScript, React, Node.js, ESLint/Prettier, vitest/jest patterns |
| **testing** | Test strategy, TDD patterns, mocking, coverage, flaky test debugging |
| **security** | Defense-in-depth, threat modeling, OWASP patterns, secure coding |
| **domain-devops** | Containerization, CI/CD patterns, Kubernetes, observability |

---

## TDD Built In

Every implementation follows a strict test-driven cycle. The developer agent will not write production code without a failing test first.

<img src="{{ site.baseurl }}/assets/images/tdd-quality-gate.png" alt="TDD Cycle — RED (write failing test), GREEN (minimum code to pass), REFACTOR (improve, tests still green), VERIFY (self-review + coverage) — then Quality Gate: all tests pass, coverage >= 80%, self-review complete" class="concept-image">

No exceptions. No shortcuts. Tests define the contract before code fills it.

---

## Get Started

```bash
claude plugin marketplace add aj-geddes/unicorn-team
claude plugin install unicorn-team@unicorn-team
```

Then ask Claude Code to build something. The orchestrator takes it from there.

[Getting Started Guide]({{ site.baseurl }}/getting-started/) -- walkthrough your first task with detailed examples.

[Skills Deep Dive]({{ site.baseurl }}/skills/) -- explore all 13 skills and how they compose.

[Architecture]({{ site.baseurl }}/architecture/) -- understand the orchestrator-first design.
