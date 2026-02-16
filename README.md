# ralph-plan

A Claude Code plugin that adds a guided brainstorming and planning phase before launching [Ralph Loop](https://github.com/anthropics/claude-code-plugins/tree/main/ralph-loop).

## What it does

Ralph Loop executes iteratively but starts blind — it needs a well-formed prompt to iterate effectively. This plugin adds a structured 7-phase flow that:

1. **Explores** project context (files, docs, git history)
2. **Gathers** requirements through focused questions (one at a time)
3. **Proposes** 2-3 approaches with trade-offs
4. **Presents** a detailed design section by section
5. **Creates** an ordered implementation plan with verification criteria
6. **Saves** the plan file and derives Ralph Loop parameters
7. **Launches** Ralph Loop automatically

Hard gates between phases prevent skipping interactive steps.

## Usage

```
/ralph-plan:ralph-plan Build a REST API for user management
```

The command takes a task description as its argument. Claude then guides you through the full planning flow before launching Ralph Loop.

## Requirements

- [ralph-loop](https://github.com/anthropics/claude-code-plugins/tree/main/ralph-loop) plugin must be installed

## Plan file format

Plans are saved to `docs/plans/YYYY-MM-DD-<topic-slug>.md` with:
- Context summary
- Chosen approach
- Ordered steps with verification commands
- Success criteria checklist

## Ralph Loop parameters

- **Completion promise** is auto-derived from success criteria (ALL_CAPS_UNDERSCORE format)
- **Max iterations** = steps x 3 (min 9, max 60)

## Cancellation

Once Ralph Loop launches, use `/ralph-loop:cancel-ralph` to stop it.

## Installation

```bash
claude --plugin-dir /home/dawsmana/ralph-plan
```

Or add to your Claude Code settings.
