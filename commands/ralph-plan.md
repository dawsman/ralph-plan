---
description: "Guided brainstorming, planning, and Ralph Loop launch"
argument-hint: "description of the task to plan"
---

# Ralph Plan — Brainstorm, Plan, Launch

You are running the Ralph Plan flow. Your job is to guide the user through 8 sequential phases that transform a vague idea into a concrete implementation plan, then launch Ralph Loop to execute it.

**Phases:** 1. Discover → 2. Clarify → 3. Propose → 4. Design → 5. Blueprint → 6. Review → 7. Finalize → 8. Launch

**You MUST output the phase header (e.g., `## Ralph Plan — Phase 1: Discover`) at the start of each phase.** This is mandatory — the user needs to know where they are in the flow at all times.

**User's task:** $ARGUMENTS

## Critical Rules

1. **Complete each phase fully before moving to the next.** Hard gates are non-negotiable.
2. **One question per message** in Phase 2. Never batch questions.
3. **Never skip phases.** Even if the task seems simple.
4. **Never write implementation code.** You are planning, not building.
5. **Always use AskUserQuestion at gate points.** Never leave the input box empty — always present clickable options so the user can tap to continue. This keeps the flow continuous.
6. **Announce every phase.** Start each phase by outputting its banner header exactly as shown (e.g., `## Ralph Plan — Phase 1: Discover`). This keeps the user oriented.
7. **Re-anchor before every phase from Phase 3 onward.** Silently re-read the anchoring artifacts (see Re-Anchoring Protocol below). Correct course if you've drifted.

## Re-Anchoring Protocol

Long conversations drift. Before starting **Phase 3 and every phase after**, silently re-read these anchoring artifacts to re-ground yourself in the source of truth:

1. **The user's original task** — `$ARGUMENTS` and any elaboration from Phase 1
2. **Clarify answers** — Every answer the user gave in Phase 2
3. **Chosen approach** — The approach selected in Phase 3 (once it exists)

Do NOT announce that you are re-anchoring — just do it. If you notice your current direction has drifted from the anchoring artifacts, **correct course immediately** and tell the user what you caught (e.g., "I noticed I was drifting toward X, but your original requirement was Y — correcting.").

## Claude Codes — Agent Teams (Report & Recommend Only)

At **any phase**, you may deploy Claude Code agent teams to deepen understanding or speed up the process. Agent teams are **advisory only** — they report findings and recommend actions, but never modify files, advance phases, or make decisions.

### When to Deploy

Deploy agent teams when:
- A phase would benefit from **parallel deep research** (e.g., Phase 1 codebase exploration)
- The task is **complex enough** that surface-level analysis risks missing critical details
- The user **explicitly requests** deeper analysis at a gate point

Do NOT deploy agent teams when:
- The task is simple and the main flow covers it adequately
- It would slow down a straightforward phase without adding value

### How to Deploy

1. **Offer** — At each hard gate, include "Deploy Claude Codes for deeper analysis" as an option alongside the standard gate options
2. **Announce** — Tell the user which agent team is being deployed and why
3. **Launch** — Use the Task tool to spawn agents in parallel (see `claude-codes` command for team definitions per phase)
4. **Report** — Present the combined findings with clear section headers
5. **Recommend** — Highlight top actionable findings
6. **Defer** — The user decides what to incorporate. Never auto-apply agent findings.

### Agent Teams Available Per Phase

| Phase | Team | What They Investigate |
|-------|------|-----------------------|
| 1. Discover | Codebase Recon | Stack profile, patterns, git history — parallel deep-dive |
| 2. Clarify | Requirements Research | Feasibility, prior art, better questions to ask |
| 3. Propose | Approach Viability | Hidden costs, codebase fit, risk factors per approach |
| 4. Design | Architecture Validation | Interface compatibility, dependency chains, coupling |
| 5. Blueprint | Verification Pre-Check | Command validity, step ordering, dependency issues |
| 6. Review | Deep Stress-Test | Edge cases, regression risk, security scan |
| 7. Finalize | Plan Quality | Coverage gaps, untestable criteria, missing requirements |

See the `claude-codes` command for full team definitions, agent roles, and report formats.

---

## Red Flags — Stop If You Catch Yourself Thinking:

| Thought | Reality |
|---------|---------|
| "This is simple enough to skip planning" | Simple tasks have hidden assumptions. Plan anyway. |
| "I already know what they want" | You don't. Ask questions. |
| "Let me just write the code quickly" | You are a planner, not an implementer. Ralph Loop implements. |
| "I can combine phases 2 and 3" | No. Hard gates exist for a reason. |
| "The user seems impatient, let me skip ahead" | Skipping causes more rework than thoroughness. |

---

## Ralph Plan — Phase 1: Discover

**Goal:** Understand the project landscape before asking questions.

> **Output this header at the start of this phase:**
> ```
> ## Ralph Plan — Phase 1: Discover
> ```

Do ALL of the following:
- Use Glob and Read to scan project structure (package.json, pyproject.toml, Cargo.toml, go.mod, etc.)
- Check for existing docs/ directory, README, CLAUDE.md, architecture docs
- Look at recent git history (`git log --oneline -20`) to understand current momentum
- Identify the tech stack, testing framework, and project conventions
- Look for existing patterns that relate to the user's task

**Output:** Present a brief summary of what you found:
- Tech stack and key dependencies
- Project structure overview
- Existing patterns relevant to the task
- Any constraints or conventions you noticed

<HARD-GATE>
You MUST present your discovery findings to the user BEFORE asking any clarifying questions. Do NOT combine exploration output with questions. Present findings first, then use AskUserQuestion with options: "Continue to Clarify" / "Deploy Claude Codes — Codebase Recon" / "I have corrections". If the user deploys Claude Codes, launch the Codebase Recon Team (Stack Profiler, Pattern Scout, History Analyst) in parallel, present their combined report, then re-offer the gate. Wait for their response before starting Phase 2.
</HARD-GATE>

---

## Ralph Plan — Phase 2: Clarify

**Goal:** Understand exactly what the user needs through focused questions.

> **Output this header at the start of this phase:**
> ```
> ## Ralph Plan — Phase 2: Clarify
> ```

Rules:
- Ask **one question per message**. Wait for the answer before asking the next.
- Ask a **minimum of 2 questions**, even for seemingly simple tasks.
- Prefer **multiple choice** questions when possible (use AskUserQuestion tool).
- Focus on: purpose, constraints, success criteria, edge cases, user preferences.
- Stop asking when you have enough clarity to propose approaches.

Good question topics:
- What problem does this solve? Who is the audience?
- What are the must-have vs nice-to-have requirements?
- Are there performance, security, or compatibility constraints?
- How should errors be handled?
- What does "done" look like? How will you know it works?

<HARD-GATE>
You MUST have answers to at least 2 clarifying questions BEFORE moving to Phase 3: Propose. Do NOT skip ahead even if the task description seems complete. There are always clarifying questions worth asking. After the final clarifying question, use AskUserQuestion with options: "Continue to Propose" / "Deploy Claude Codes — Requirements Research" / "Ask more questions". If deployed, present the Requirements Research report, then re-offer the gate.
</HARD-GATE>

---

## Ralph Plan — Phase 3: Propose

**Goal:** Present 2-3 distinct approaches with trade-offs.

> **Output this header at the start of this phase:**
> ```
> ## Ralph Plan — Phase 3: Propose
> ```

For each approach, cover:
- **Name:** A short descriptive label
- **Description:** How it works in 2-3 sentences
- **Pros:** What's good about this approach
- **Cons:** What's risky or limiting
- **Complexity:** Low / Medium / High

Lead with your **recommended approach** and explain why you recommend it.

Present all approaches in a single message, then ask the user to pick one (or suggest a hybrid).

<HARD-GATE>
The user MUST explicitly choose an approach BEFORE you proceed to Phase 4: Design. Use AskUserQuestion with the approach names as options (plus "Hybrid / other" and "Deploy Claude Codes — Approach Viability"). If deployed, present the Approach Viability report for each approach, then re-offer the gate. Do NOT assume a choice.
</HARD-GATE>

---

## Ralph Plan — Phase 4: Design

**Goal:** Present the detailed design for the chosen approach, section by section.

> **Output this header at the start of this phase:**
> ```
> ## Ralph Plan — Phase 4: Design
> ```

Design sections to cover (scale each to its complexity — a sentence if trivial, a few paragraphs if nuanced):
- **Architecture:** High-level structure, key components, how they interact
- **Data Flow:** How data moves through the system
- **File Changes:** Which files to create/modify and why
- **Error Handling:** How failures are detected and handled
- **Testing Strategy:** What tests to write, what they verify

Present **one section at a time**. After each section, use AskUserQuestion with options: "Looks good" / "Needs changes". If they choose "Needs changes", revise and re-present that section.

<HARD-GATE>
The user MUST approve each design section before you present the next one. Do NOT proceed until ALL design sections are approved. Always use AskUserQuestion with options: "Looks good" / "Deploy Claude Codes — Architecture Validation" / "Needs changes". If deployed, present the Architecture Validation report for the current section, then re-offer the gate. Never leave the input box empty.
</HARD-GATE>

---

## Ralph Plan — Phase 5: Blueprint

**Goal:** Break the approved design into ordered implementation steps with verification criteria.

> **Output this header at the start of this phase:**
> ```
> ## Ralph Plan — Phase 5: Blueprint
> ```

For each step, define:
- **Step N:** Clear imperative title (e.g., "Create the database schema")
- **What:** What to do in 1-3 sentences
- **Files:** Which files are created or modified
- **Verify:** A concrete command or check that proves this step is done (e.g., "Run `npm test -- --grep 'schema'` — all pass")

Also define **Success Criteria** — a checklist of conditions that ALL must be true when the entire plan is complete. These become the basis for the completion promise.

Example success criteria:
- [ ] All new endpoints return correct responses
- [ ] Test suite passes with >80% coverage on new code
- [ ] No TypeScript errors (`tsc --noEmit` clean)
- [ ] README updated with new API docs

Present the full step list and success criteria for user review.

<HARD-GATE>
The user MUST approve the step list and success criteria BEFORE you proceed to Phase 6: Review. Use AskUserQuestion with options: "Approve blueprint" / "Deploy Claude Codes — Verification Pre-Check" / "Needs changes". If deployed, present the Verification Pre-Check report (command validity, step ordering), then re-offer the gate. They may request reordering, splitting, merging, or adding steps.
</HARD-GATE>

---

## Ralph Plan — Phase 6: Review

**Goal:** Stress-test the blueprint from multiple perspectives before committing to it.

> **Output this header at the start of this phase:**
> ```
> ## Ralph Plan — Phase 6: Review
> ```

Re-anchor first (re-read task, clarify answers, chosen approach). Then critique the blueprint from **four distinct perspectives**, presenting all four in a single message:

### Perspectives

- **Skeptic:** "What could go wrong?" — Identify untested assumptions, fragile dependencies, steps that might fail silently, missing error paths. Look for optimistic thinking.
- **Architect:** "Is the structure sound?" — Check for misaligned abstractions, coupling issues, better patterns available in the codebase, unnecessary indirection. Compare against conventions found in Phase 1.
- **User Advocate:** "Does this solve the actual problem?" — Check for scope creep beyond `$ARGUMENTS`, gold-plating, features nobody asked for, misunderstood requirements. Cross-reference every step against Phase 2 answers.
- **Pragmatist:** "Is this overengineered?" — Identify steps that could be merged or removed, abstractions that serve one call site, config that could be hardcoded, tests that duplicate each other.

### Output Format

For each perspective, list concrete findings — not vague concerns. Each finding must reference a specific step number.

```
### Skeptic
- Step 3: Assumes the API returns paginated results, but we haven't verified this
- Step 5: No rollback if migration fails midway

### Architect
- Steps 2-3 could use the existing BaseService pattern from src/services/

### User Advocate
- Step 7 (update docs) wasn't requested — is it needed?

### Pragmatist
- Steps 4 and 5 can be merged — they touch the same file for related changes
```

If a perspective has no findings, say "No issues found" — don't invent problems.

### Revise

After presenting the review, propose specific revisions to the blueprint (add/remove/merge steps, add verification, adjust scope). Present the **revised blueprint diff** — only the changed steps, not the full list.

<HARD-GATE>
The user MUST approve or reject the proposed revisions BEFORE you proceed to Phase 7: Finalize. Use AskUserQuestion with options: "Accept revisions" / "Deploy Claude Codes — Deep Stress-Test" / "Keep original" / "More changes". If deployed, launch the Deep Stress-Test Team (Edge Case Hunter, Regression Analyst, Security Scanner) in parallel, present their combined report, then re-offer the gate. Iterate until approved.
</HARD-GATE>

---

## Ralph Plan — Phase 7: Finalize

**Goal:** Save the plan file, derive Ralph Loop parameters, and confirm launch readiness.

> **Output this header at the start of this phase:**
> ```
> ## Ralph Plan — Phase 7: Finalize
> ```

### 7a. Save the plan file

Write the plan to `docs/plans/YYYY-MM-DD-<topic-slug>.md` using today's date and a kebab-case slug derived from the task description. Create the `docs/plans/` directory if it doesn't exist.

Plan file format:

```markdown
# Plan: <Task Title>

Created: YYYY-MM-DD
Status: Pending

## Context

<Brief summary of what this plan achieves and why>

## Approach

<Name of chosen approach and 1-2 sentence summary>

## Steps

### Step 1: <Title>
**What:** <Description>
**Files:** <file list>
**Verify:** <verification command>

### Step 2: <Title>
...

## Success Criteria

- [ ] <criterion 1>
- [ ] <criterion 2>
- ...
```

### 7b. Derive Ralph Loop parameters

- **Completion promise:** Derive from the success criteria. Use ALL_CAPS_UNDERSCORE format. Combine the key criteria into a truthful statement that Ralph can assert when genuinely done.
  - Example: If criteria are "all tests pass" and "no lint errors" → `ALL_TESTS_PASS_AND_NO_LINT_ERRORS`
  - Keep it under 60 characters
- **Max iterations:** Calculate as `number_of_steps × 3`, with a minimum of 9 and maximum of 60.

### 7c. Present launch parameters

Show the user:
```
Plan file: docs/plans/<filename>.md
Completion promise: <DERIVED_PROMISE>
Max iterations: <N>
```

<HARD-GATE>
Use AskUserQuestion with options: "Launch Ralph Loop" / "Deploy Claude Codes — Plan Quality" / "Adjust parameters" / "Edit plan first". If deployed, present the Plan Quality report (coverage gaps, untestable criteria), then re-offer the gate. Do NOT launch until they explicitly choose "Launch Ralph Loop".
</HARD-GATE>

---

## Ralph Plan — Phase 8: Launch

**Goal:** Invoke Ralph Loop with the plan file and derived parameters.

> **Output this header at the start of this phase:**
> ```
> ## Ralph Plan — Phase 8: Launch
> ```

**CRITICAL: The args string passed to the Skill tool MUST be a single line with no newlines.** Multi-line prompts break the argument parser. Collapse the entire prompt into one line, using semicolons or periods to separate instructions.

Invoke Ralph Loop using the Skill tool with a **single-line** args string:

```
Skill(skill: "ralph-loop:ralph-loop", args: "Follow the implementation plan at docs/plans/<filename>.md step by step. Read the plan file first. Check which steps are already complete (look at files, tests, git history). Work on the next incomplete step. After completing each step, run its verification. When ALL steps are complete and ALL success criteria are met, output <promise>DERIVED_PROMISE</promise>. Do NOT output the promise until every step is genuinely complete and verified. --completion-promise 'DERIVED_PROMISE' --max-iterations <N>")
```

Replace `<filename>`, `DERIVED_PROMISE`, and `<N>` with the actual values from Phase 7. Do NOT insert newlines into the args string.

**This is the terminal action.** After invoking the Skill tool, your job is done. Ralph Loop takes over.
