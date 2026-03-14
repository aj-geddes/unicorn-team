# Loop Prompt: Continuous Codebase Development with the Unicorn Team

Use Claude Code's `/loop` command to run the unicorn-team on an interval,
progressively building out an entire codebase across multiple iterations.

Each loop iteration picks up where the last left off — planning what's next,
implementing, testing, reviewing, and moving on to the next piece.

---

## Setup

Before starting the loop, run this initialization prompt once to establish the
project plan:

```
/orchestrator

I'm building: [describe your project in 2-3 sentences]

Example: "A REST API for a bookstore inventory system. It needs CRUD endpoints
for books, authors, and categories, with SQLite storage, input validation,
pagination, and JWT auth. Python with FastAPI."

Before we start building, I need you to:

1. **Architect** — Produce a full implementation plan:
   - Break the project into ordered, independently-testable milestones
   - Each milestone should be completable in one development cycle
   - List milestones in dependency order (foundations first)
   - For each milestone, specify: module, tests to write, acceptance criteria
   - Write this plan to `PLAN.md` in the project root

2. **Architect** — Create the project skeleton:
   - Directory structure
   - Configuration files (pyproject.toml, tsconfig.json, etc.)
   - Entry point stubs
   - Test infrastructure (conftest.py, test utils, etc.)

Commit the skeleton and plan. Do not implement any features yet.
```

---

## The Loop Prompt

Once your `PLAN.md` exists and the skeleton is committed, start the loop:

```
/loop 10m /orchestrator

You are developing a codebase iteratively. Each cycle you must make forward
progress on the project.

## Your cycle protocol:

### 1. Orient (30 seconds)
Read `PLAN.md` and check git log to determine:
- Which milestones are DONE (have passing tests and committed code)
- Which milestone is NEXT (first incomplete milestone in order)
- If all milestones are done, move to the Finalize phase

### 2. Implement the next milestone
Delegate to the full pipeline for the current milestone:

- **Developer** — TDD the milestone:
  - RED: Write failing tests for this milestone's acceptance criteria
  - GREEN: Implement minimum code to pass
  - REFACTOR: Clean up
  - Run all tests (not just new ones) to catch regressions

- **QA-Security** — Review the new code:
  - 4-layer review (automated, logic, design, security)
  - Flag any issues medium severity or above

- **Developer** (if needed) — Fix QA findings and re-verify

### 3. Gate check
Verify before marking complete:
- [ ] All tests pass (including previous milestones)
- [ ] Coverage >= 80%
- [ ] No TODO/FIXME/HACK markers
- [ ] No debug code
- [ ] QA review passed

### 4. Update progress
- Update `PLAN.md`: mark the completed milestone as DONE with date
- Commit all changes with message: `feat(milestone-N): <description>`

### 5. Finalize (only when all milestones are DONE)
When every milestone in PLAN.md is marked DONE:

- **QA-Security** — Full codebase review (not just latest changes)
- **DevOps** — Set up CI pipeline (GitHub Actions) with:
  - Test suite on push/PR
  - Linting and type checking
  - Coverage reporting
- **Developer** — Fix any final QA findings
- Update `PLAN.md` with "PROJECT COMPLETE" and final summary
- Stop looping (tell the user the project is finished)

Report what you completed this cycle and what the next cycle will tackle.
```

---

## What Happens

The loop runs every 10 minutes (configurable). Each iteration:

1. **Reads the plan** to find the next incomplete milestone
2. **Implements it** with full TDD discipline via the Developer agent
3. **Reviews it** via the QA-Security agent
4. **Fixes issues** if the review found any
5. **Commits and updates the plan** marking progress
6. **Reports status** so you can monitor from the chat

Over several iterations, your entire codebase gets built out milestone by
milestone, with tests, reviews, and quality gates at every step.

---

## Tuning the Interval

```bash
/loop 5m  ...   # Fast iteration for small milestones
/loop 10m ...   # Default — good for medium features (100-300 lines each)
/loop 20m ...   # Complex milestones that need more agent time
```

Pick an interval that gives agents enough time to complete a full cycle. If a
cycle is still running when the next fires, it waits — no work is lost.

---

## Monitoring and Control

While the loop runs, you can interact normally in your session:

```bash
# Check what's scheduled
what scheduled tasks do I have?

# Watch progress
cat PLAN.md

# Pause if you need to intervene
cancel the orchestrator loop

# Resume after making manual changes
/loop 10m /orchestrator [paste the cycle prompt above]
```

---

## Tips

- **Front-load the plan.** The setup step is the most important. A clear,
  ordered `PLAN.md` with small milestones keeps each cycle focused and fast.
- **Keep milestones small.** Each should be 50-200 lines of implementation.
  Smaller milestones = faster cycles = more frequent commits.
- **Let it run.** The loop handles its own coordination. Check back every
  30-60 minutes to review commits and course-correct if needed.
- **Intervene when needed.** If a milestone goes sideways, cancel the loop,
  fix the issue manually or adjust `PLAN.md`, then restart.
- **Session-scoped.** Loops only run while your Claude Code session is open.
  If you close the session, restart the loop when you return.
- **3-day expiry.** Scheduled tasks auto-expire after 3 days. For longer
  projects, restart the loop as needed.

---

## Customization

### Add a DevOps milestone early
If you want CI from the start, add this to your `PLAN.md` setup prompt:
```
Include a milestone after the first feature milestone to set up CI/CD
with GitHub Actions (test, lint, coverage).
```

### Skip QA on early milestones
For rapid prototyping, simplify the cycle:
```
For milestones 1-3, skip QA review. Starting from milestone 4, include
full QA-Security review on each cycle.
```

### Add documentation
Append to the Finalize phase:
```
- **Architect** — Generate API documentation and a README with usage
  examples, installation instructions, and architecture overview.
```
