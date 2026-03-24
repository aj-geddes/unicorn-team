---
layout: default
title: "Architecture — How Claude Code Agents Orchestrate Multi-Agent Pipelines"
description: "Deep dive into how the unicorn-team Claude Code plugin coordinates 5 AI agents with 200K context windows, quality gates, TDD enforcement, and parallel delegation for professional software engineering."
permalink: /architecture/
---

# Architecture

The 10X Developer Unicorn uses an **orchestrator-first design**: a lightweight coordinator skill in the main context, backed by 5 specialized agents defined in `agents/` that spawn as subprocesses via the Agent tool. Each agent gets its own fresh 200K context window with preloaded skills, providing true context isolation.

---

## Design Principles

**Route, don't implement.** The orchestrator analyzes and delegates. It never writes code, creates infrastructure, or designs systems itself. Every substantial task goes to a specialist.

**Context is a public good.** Each subagent gets a fresh 200K token context window. The orchestrator stays lean (under 40K tokens) and passes only what each agent needs -- task description, relevant context, and constraints. Agents return summaries and file paths, not full outputs.

**TDD is non-negotiable.** Every implementation follows RED (failing test) -> GREEN (make it pass) -> REFACTOR (improve) -> VERIFY (self-review). No exceptions. No shortcuts.

**Quality gates at every handoff.** Every transition between agents passes through a gate: tests pass, coverage meets threshold, self-review completed, no debug code, no unresolved markers.

---

## The Agent Squad

<div class="diagram">
  <div class="flow">
    <div class="flow-node bg-blue">Orchestrator<small>Coordination + Routing</small></div>
    <div class="flow-arrow"></div>
    <div class="flow-fan">
      <div class="flow-node bg-mauve">Architect<small>System Design</small></div>
      <div class="flow-node bg-green">Developer<small>TDD Implementation</small></div>
      <div class="flow-node bg-peach">QA-Security<small>Review + Audit</small></div>
      <div class="flow-node bg-teal">DevOps<small>Deploy + Monitor</small></div>
      <div class="flow-node bg-yellow">Polyglot<small>Language Expert</small></div>
    </div>
  </div>
</div>

| Component | Type | Definition | Role |
|-----------|------|------------|------|
| **Orchestrator** | Skill | `skills/orchestrator/SKILL.md` | Routes tasks, coordinates agents, enforces quality gates |
| **Architect** | Agent | `agents/architect.md` | System design, pattern selection, tradeoff analysis |
| **Developer** | Agent | `agents/developer.md` | Full-stack TDD implementation (Python, JS/TS, Go, Rust) |
| **QA-Security** | Agent | `agents/qa-security.md` | Code review, security audits, quality gate enforcement |
| **DevOps** | Agent | `agents/devops.md` | CI/CD, infrastructure, deployment, monitoring |
| **Polyglot** | Agent | `agents/polyglot.md` | Language acquisition, cross-ecosystem pattern transfer |

### Agent Definitions

Each agent is defined as a `.md` file in `agents/` with frontmatter specifying model, tools, and composable skills. Agent protocol content (TDD workflow, review checklists, deployment procedures, etc.) is inlined directly in the agent definition body rather than loaded as separate skills, so only user-invocable skills appear as slash commands.

| Agent | Model | Composable Skills |
|-------|-------|-------------------|
| developer | sonnet | self-verification, testing, python, javascript, go |
| architect | opus | pattern-transfer, code-reading, technical-debt |
| qa-security | sonnet | security, testing |
| devops | sonnet | domain-devops, security |
| polyglot | opus | language-learning, pattern-transfer, code-reading |

Agent reference materials (detailed examples, templates, runbooks) are stored in `.claude/protocols/{agent}/references/` and accessed on-demand via the Read tool.

---

## Delegation Workflow

A complex feature request flows through multiple agents with quality gates at each transition.

<div class="diagram">
  <div class="sequence">
    <div class="seq-step">
      <div class="seq-dot bg-pink"></div>
      <div class="seq-content">
        <div class="seq-label" style="color: #f5c2e7;">You &rarr; Orchestrator</div>
        <div class="seq-detail">"Build user authentication"</div>
      </div>
    </div>
    <div class="seq-step">
      <div class="seq-dot bg-blue"></div>
      <div class="seq-content">
        <div class="seq-label text-blue">Orchestrator &rarr; Architect</div>
        <div class="seq-detail">Analyze complexity, delegate design</div>
      </div>
    </div>
    <div class="seq-step">
      <div class="seq-dot bg-mauve"></div>
      <div class="seq-content">
        <div class="seq-label text-mauve">Architect &rarr; Orchestrator</div>
        <div class="seq-detail">Returns ADR + API contract + data model</div>
      </div>
    </div>
    <div class="seq-gate">Quality Gate: Design reviewed</div>
    <div class="seq-step">
      <div class="seq-dot bg-green"></div>
      <div class="seq-content">
        <div class="seq-label text-green">Developer implements (TDD)</div>
        <div class="seq-detail">RED: write failing tests &rarr; GREEN: implement auth &rarr; REFACTOR: clean up &rarr; VERIFY: self-review</div>
      </div>
    </div>
    <div class="seq-gate">Quality Gate: Tests pass, coverage &ge; 80%</div>
    <div class="seq-step">
      <div class="seq-dot bg-peach"></div>
      <div class="seq-content">
        <div class="seq-label text-peach">QA-Security reviews</div>
        <div class="seq-detail">Code review + security audit &rarr; Approved with findings</div>
      </div>
    </div>
    <div class="seq-step">
      <div class="seq-dot bg-pink"></div>
      <div class="seq-content">
        <div class="seq-label" style="color: #f5c2e7;">Orchestrator &rarr; You</div>
        <div class="seq-detail">Complete implementation + review report</div>
      </div>
    </div>
  </div>
</div>

---

## Routing Decision Tree

The orchestrator uses a decision tree to match tasks to agents:

| Task Type | Route | Why |
|-----------|-------|-----|
| Simple question | Answer directly | No agent overhead needed |
| Bug fix | root-cause-debugger -> Developer | Systematic diagnosis before fix |
| Feature (< 200 lines) | Developer (TDD) | Single agent, full cycle |
| Feature (complex) | Architect -> Developer -> QA | Design first, then implement, then review |
| Architecture decision | Architect | Design artifacts, not code |
| Code review | QA-Security | Structured review with security lens |
| Deployment / infra | DevOps | Production-grade infrastructure |
| New language | Polyglot -> Developer | Learn first, then implement |
| Multi-domain (complex) | Parallel delegation -> Aggregate | Independent tasks run simultaneously |
| Estimation | Estimation skill | PERT-based risk analysis |

---

## Context Window Efficiency

Context windows are the scarcest resource in an AI system. The unicorn architecture treats them deliberately.

**Orchestrator stays lean (~37K tokens)**

| Budget Item | Tokens |
|-------------|--------|
| System prompt | ~5K |
| Conversation history | ~10K |
| Skill metadata (all 13) | ~2K |
| Active skill body | ~5K |
| Working memory | ~10K |
| Response buffer | ~5K |

**Subagents get fresh context**

Each agent invocation (via the Agent tool with `agents/*.md` definitions) starts with a clean 200K context window. The orchestrator passes only what's needed:

- Task description (~500 tokens)
- Relevant context (~2-3K tokens)
- Constraints and expected output (~500 tokens)

Agents return summaries and file paths -- not full outputs. The orchestrator never accumulates subagent implementation details in its own context.

**Checkpoint protocol for long tasks**: When context exceeds 100K tokens, the orchestrator writes a checkpoint summary to a file, resets context with the checkpoint, and continues.

---

## Quality Gates

Quality gates are enforced at every transition. Nothing passes without meeting the standard.

### Post-Implementation Gate (Developer -> Orchestrator)

- All tests pass (100% pass rate)
- Coverage >= 80% (90%+ for critical paths)
- Self-verification completed
- No TODO/FIXME/HACK markers
- No debug code (console.log, breakpoint, print)

### Pre-Review Gate (Orchestrator -> QA)

- Implementation complete
- Developer self-review passed
- Tests and coverage verified

### Final Gate (Orchestrator -> You)

- All quality gates passed
- Deliverables complete
- Summary clear and actionable

---

## The Hidden 80% Philosophy

Most AI coding tools optimize for one thing: generating code faster. But writing code is only about 20% of what professional software engineers do.

The other 80% includes:

- **Reading and understanding** existing codebases before making changes
- **Recognizing patterns** -- seeing that today's problem is the same shape as yesterday's, just in different clothes
- **Estimating realistically** -- with risk buffers, stated assumptions, and confidence levels
- **Reviewing your own work** before anyone else sees it
- **Managing technical debt** deliberately -- knowing when to take shortcuts and tracking the cost
- **Thinking about security** as a mindset, not a checklist
- **Debugging systematically** -- forming hypotheses and testing them, not guessing

The 10X Developer Unicorn encodes all of these skills into a coordinated system. The result is Claude Code that works the way a senior engineering team works: with discipline, judgment, and accountability.

[Explore the full skill set]({{ site.baseurl }}/skills/) | [Get started in one command]({{ site.baseurl }}/getting-started/)
