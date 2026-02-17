# ralph-plan

A Claude Code plugin that adds a guided brainstorming and planning phase before launching [Ralph Loop](https://github.com/anthropics/claude-code-plugins/tree/main/ralph-loop).

## What it does

Ralph Loop executes iteratively but starts blind — it needs a well-formed prompt to iterate effectively. This plugin adds a structured 8-phase flow that transforms a vague idea into a concrete implementation plan:

| Phase | Name | What happens |
|-------|------|-------------|
| 1 | **Discover** | Scans project context — tech stack, structure, conventions, git history |
| 2 | **Clarify** | Asks focused questions one at a time to nail down requirements |
| 3 | **Propose** | Presents 2-3 approaches with trade-offs, you pick one |
| 4 | **Design** | Walks through architecture, data flow, file changes, error handling, testing — one section at a time |
| 5 | **Blueprint** | Breaks the design into ordered implementation steps with verification commands |
| 6 | **Review** | Stress-tests the blueprint from 4 perspectives before committing |
| 7 | **Finalize** | Saves the plan file, derives Ralph Loop parameters |
| 8 | **Launch** | Invokes Ralph Loop with the plan and completion promise |

Hard gates between phases prevent skipping — every gate uses clickable options so you tap to continue rather than typing.

## Key features

### Re-anchoring

Long conversations drift. From Phase 3 onward, the model silently re-reads your original task, your clarify answers, and the chosen approach before each phase. If it catches itself drifting, it corrects course and tells you.

### Multi-perspective review

Phase 6 critiques the blueprint from four angles before you commit:

- **Skeptic** — untested assumptions, fragile dependencies, missing error paths
- **Architect** — structural soundness, existing patterns missed, coupling issues
- **User Advocate** — scope creep, gold-plating, misunderstood requirements
- **Pragmatist** — overengineering, steps to merge or remove

Each finding references a specific step number. After the review, revisions are proposed as a diff.

### Continuous flow

Every hard gate uses `AskUserQuestion` with clickable options — no empty input boxes, no typing "continue". The flow keeps moving with minimal friction.

## Commands

### `/ralph-plan <task description>`

Start the full 8-phase planning flow.

```
/ralph-plan Add user authentication with JWT
/ralph-plan Refactor the cache layer to use Redis
/ralph-plan Build a CLI tool for database migrations
```

### `/ralph-plan help`

Explains the plugin, all 8 phases, and how it fits with Ralph Loop.

## When to use

| Situation | Use |
|-----------|-----|
| Vague idea, no plan yet | `/ralph-plan` |
| Clear task, well-defined steps | `/ralph-loop` directly |
| Existing plan file | `/ralph-loop` with the plan |
| Need to explore approaches first | `/ralph-plan` |
| Simple bug fix or small change | Neither — just do it |

## Plan file format

Plans are saved to `docs/plans/YYYY-MM-DD-<topic-slug>.md` with:
- Context summary
- Chosen approach
- Ordered steps with verification commands
- Success criteria checklist

## Ralph Loop parameters

- **Completion promise** is auto-derived from success criteria (ALL_CAPS_UNDERSCORE format)
- **Max iterations** = steps x 3 (min 9, max 60)

## Requirements

- [ralph-loop](https://github.com/anthropics/claude-code-plugins/tree/main/ralph-loop) plugin must be installed

## Cancellation

Once Ralph Loop launches, use `/cancel-ralph` to stop it.

## Installation

```bash
claude plugin add /path/to/ralph-plan
```

Or add to your Claude Code settings.
