# One-Shot Prompt: Build a Feature with the Unicorn Team

Copy and paste the prompt below into Claude Code to execute a complete feature
implementation using the full unicorn-team agent pipeline.

Replace the `[bracketed]` sections with your specific requirements.

---

## The Prompt

```
/orchestrator

I need you to build the following feature using the full unicorn-team pipeline:

## Feature
[Describe the feature you want built. Be specific about what it should do, not how.]

Example: "A CLI password strength validator that scores passwords 0-100, checks against
common password lists, enforces minimum length/complexity rules, and returns structured
JSON output."

## Target
- Language: [python | typescript | go | rust]
- Location: [path/to/module or "new project in ./project-name"]
- Entry point: [e.g., "src/validator.py" or "let the architect decide"]

## Requirements
- [Requirement 1: e.g., "Must handle Unicode passwords"]
- [Requirement 2: e.g., "Must run in under 100ms for any input"]
- [Requirement 3: e.g., "Zero external dependencies"]

## Constraints
- [Any architectural constraints, e.g., "No database", "Must be a pure function"]
- [Any compatibility constraints, e.g., "Python 3.10+", "Node 18+"]

## Execute the full pipeline:

1. **Architect** — Design the module structure, data model, and API surface.
   Produce an ADR documenting the key design decisions.

2. **Developer** — Implement using strict TDD:
   - RED: Write failing tests that cover all requirements + edge cases
   - GREEN: Write minimum code to pass every test
   - REFACTOR: Clean up without breaking tests
   Return the code, tests, and coverage report.

3. **QA-Security** — Run a full 4-layer review:
   - Automated: linting, type checking, test pass rate
   - Logic: correctness, edge cases, error handling
   - Design: API clarity, naming, separation of concerns
   - Security: input validation, injection risks, OWASP checks
   Return findings with file:line references and severity ratings.

4. **Developer** (fix pass) — Address any QA findings rated medium or above.
   Re-run tests and confirm all pass.

5. **Final gate check** — Confirm:
   - [ ] All tests pass
   - [ ] Coverage >= 80%
   - [ ] No TODO/FIXME/HACK markers
   - [ ] No debug code (print/console.log/breakpoint)
   - [ ] QA findings resolved

Return the standard orchestrator summary with changes, tests, quality gates, and
any follow-up notes.
```

---

## What Happens

When you run this prompt, the orchestrator skill activates and:

1. **Analyzes** your request and routes it as a complex multi-phase feature
2. **Spawns the Architect agent** (Opus, 200K context) to design the solution
3. **Spawns the Developer agent** (Sonnet, 200K context) with the architecture
   to implement via TDD
4. **Spawns the QA-Security agent** (Sonnet, 200K context) to review everything
5. **Spawns the Developer agent** again if QA found issues
6. **Enforces quality gates** at every handoff between agents
7. **Returns a structured summary** of all changes, tests, and quality status

Each agent gets a fresh 200K token context window, so even large implementations
stay within limits.

---

## Tips

- **Be specific about behavior, not implementation.** Say "rejects passwords
  under 8 characters" not "use a regex to check length."
- **List edge cases as requirements.** If you care about empty input, Unicode,
  or huge payloads, say so.
- **Skip steps if you want.** For a small feature, drop the Architect step:
  remove step 1 and let the Developer handle design inline.
- **Add a DevOps step** if you need CI/CD:
  ```
  6. **DevOps** — Create a GitHub Actions workflow for CI that runs
     tests on push to main and PRs. Include linting and coverage reporting.
  ```
