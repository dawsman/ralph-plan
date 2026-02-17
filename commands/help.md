---
description: "Explain Ralph Plan plugin and how it fits with Ralph Loop"
---

# Ralph Plan Help

Please explain the following to the user:

## What is Ralph Plan?

Ralph Plan is a guided brainstorming and planning workflow that takes a vague idea and transforms it into a concrete implementation plan — then hands it off to Ralph Loop for execution.

**Where it fits:**

```
You have an idea → /ralph-plan → Structured plan → /ralph-loop → Working code
```

Ralph Plan is the **entry point** for users who don't have a plan yet. If you already have a plan file, skip straight to `/ralph-loop`.

## The 8 Phases

| Phase | Name | What happens |
|-------|------|-------------|
| 1 | **Discover** | Scans your project — tech stack, structure, conventions, git history |
| 2 | **Clarify** | Asks focused questions one at a time to understand requirements |
| 3 | **Propose** | Presents 2-3 approaches with trade-offs, you pick one |
| 4 | **Design** | Walks through architecture, data flow, file changes, error handling, testing — one section at a time |
| 5 | **Blueprint** | Breaks the design into ordered implementation steps with verification commands |
| 6 | **Review** | Stress-tests the blueprint from 4 perspectives (Skeptic, Architect, User Advocate, Pragmatist) |
| 7 | **Finalize** | Saves the plan file, derives Ralph Loop parameters |
| 8 | **Launch** | Invokes `/ralph-loop` with the plan and completion promise |

Every phase has a hard gate — you approve before it moves on. All gates use clickable options so you can tap to continue.

## Built-in Safeguards

- **Re-anchoring:** From Phase 3 onward, the model silently re-reads your original task, your answers, and the chosen approach before each phase to prevent drift.
- **Multi-perspective review:** Phase 6 critiques the plan from four angles before you commit to it.
- **Hard gates:** No phase advances without your explicit approval.

## Commands

### /ralph-plan \<task description\>

Start the full 8-phase planning flow.

**Examples:**
```
/ralph-plan Add user authentication with JWT
/ralph-plan Refactor the cache layer to use Redis
/ralph-plan Build a CLI tool for database migrations
```

### Related Commands (from Ralph Loop plugin)

- `/ralph-loop <prompt> [options]` — Start an execution loop (use after planning, or standalone)
- `/cancel-ralph` — Cancel an active Ralph Loop

## When to Use Ralph Plan vs Ralph Loop Directly

| Situation | Use |
|-----------|-----|
| Vague idea, no plan yet | `/ralph-plan` |
| Clear task, well-defined steps | `/ralph-loop` directly |
| Existing plan file in `docs/plans/` | `/ralph-loop` with the plan |
| Need to explore approaches first | `/ralph-plan` |
| Simple bug fix or small change | Neither — just do it |

## How It Works With Ralph Loop

Ralph Plan's final phase automatically invokes `/ralph-loop` with:
- The saved plan file path
- A completion promise derived from your success criteria
- A max iteration count based on the number of steps

You don't need to configure Ralph Loop manually — Ralph Plan does it for you.
