---
description: "Deploy Claude Code agent teams into a Ralph Plan phase — report and recommend only"
argument-hint: "phase number or name (e.g. '3' or 'propose')"
hide-from-slash-command-tool: "true"
---

# Claude Codes — Agent Teams for Ralph Plan

You are dispatching Claude Code agent teams into the current Ralph Plan session. Agent teams **report and recommend only** — they never modify files, never advance phases, and never take autonomous action.

**Target phase:** $ARGUMENTS

## Core Principle: Report and Recommend Only

Claude Code agent teams are advisory. They exist to:
1. **Deepen understanding** — surface insights the main flow might miss
2. **Speed up** — run parallel investigations so the user doesn't wait

They do NOT:
- Write or edit files
- Advance the Ralph Plan to the next phase
- Make decisions on behalf of the user
- Override or contradict user-approved choices

Every agent team produces a **structured report** that the user can accept, reject, or ignore. The main Ralph Plan flow remains the source of truth.

---

## Agent Teams by Phase

Each phase has one or more agent teams available. Deploy them using the Task tool with the specified subagent_type. All agents receive the same instruction suffix:

> **"Report your findings in a structured format. Do NOT modify any files. Do NOT take any action. Recommend next steps but let the user decide."**

---

### Phase 1: Discover — Codebase Recon Team

**Purpose:** Parallel deep-dive into project context that would take the main flow too long.

| Agent | Subagent Type | Mission |
|-------|---------------|---------|
| **Stack Profiler** | Explore | Map every dependency, framework version, and build tool. Flag outdated or conflicting versions. |
| **Pattern Scout** | Explore | Find architectural patterns, conventions, and idioms used across the codebase. Note inconsistencies. |
| **History Analyst** | Bash | Analyze git history — active areas, recent refactors, contributors, velocity. Identify files with high churn. |

**Report format:**
```
## Codebase Recon Report

### Stack Profile
- <dependency inventory with versions>
- <conflicts or outdated packages flagged>

### Patterns Found
- <architectural patterns with file references>
- <conventions (naming, structure, testing)>
- <inconsistencies worth noting>

### History Analysis
- <active areas and recent momentum>
- <high-churn files relevant to the task>
- <recent refactors that might affect planning>

### Recommendations
- <what the main flow should pay attention to>
```

---

### Phase 2: Clarify — Requirements Research Team

**Purpose:** Pre-research technical questions so the main flow asks better-informed questions.

| Agent | Subagent Type | Mission |
|-------|---------------|---------|
| **Feasibility Analyst** | Explore | Investigate whether the user's task is feasible given the current codebase. Find blockers early. |
| **Prior Art Scout** | Explore | Search the codebase for similar features already implemented. Find patterns to reuse or avoid. |

**Report format:**
```
## Requirements Research Report

### Feasibility Assessment
- <can the task be done with the current stack?>
- <blockers or constraints found>
- <dependencies that might need updating>

### Prior Art
- <similar features already in the codebase>
- <patterns that could be reused>
- <antipatterns to avoid (with evidence)>

### Suggested Clarify Questions
- <questions the main flow should consider asking>
```

---

### Phase 3: Propose — Approach Viability Team

**Purpose:** Evaluate proposed approaches with deeper technical analysis before the user chooses.

| Agent | Subagent Type | Mission |
|-------|---------------|---------|
| **Viability Checker** | Explore | For each proposed approach, check if the codebase can actually support it. Find hidden costs. |
| **Benchmark Scout** | general-purpose | Research external best practices, common pitfalls, and performance characteristics for each approach. |

**Report format:**
```
## Approach Viability Report

### Approach A: <name>
- **Codebase fit:** <how well it aligns with existing patterns>
- **Hidden costs:** <integration effort, migration needs, tech debt>
- **Risk factors:** <what could go wrong>

### Approach B: <name>
- (same structure)

### Recommendation
- <which approach has the best fit and why>
- <risks the user should weigh>
```

---

### Phase 4: Design — Architecture Validation Team

**Purpose:** Validate each design section against the real codebase before the user approves.

| Agent | Subagent Type | Mission |
|-------|---------------|---------|
| **Interface Checker** | Explore | Verify that proposed interfaces, data shapes, and contracts are compatible with existing code. |
| **Dependency Mapper** | Explore | Trace the dependency chain for proposed changes. Flag circular dependencies or tight coupling. |

**Report format:**
```
## Architecture Validation Report

### Interface Compatibility
- <proposed interfaces vs existing contracts>
- <breaking changes flagged>
- <type mismatches or shape conflicts>

### Dependency Analysis
- <dependency chain for proposed changes>
- <coupling concerns>
- <circular dependency risks>

### Recommendations
- <adjustments to improve compatibility>
```

---

### Phase 5: Blueprint — Verification Pre-Check Team

**Purpose:** Validate that blueprint verification commands will actually work before committing to them.

| Agent | Subagent Type | Mission |
|-------|---------------|---------|
| **Command Validator** | Explore | Check that every verification command in the blueprint exists and is correctly configured (test runners, lint configs, build commands). |
| **Order Analyst** | general-purpose | Analyze step ordering for dependency issues — would step N actually work before step N+1 is done? |

**Report format:**
```
## Blueprint Pre-Check Report

### Verification Commands
- Step N: `<command>` — <valid / needs adjustment / missing config>
- ...

### Step Ordering
- <dependency issues found>
- <steps that could be parallelized>
- <steps that must be sequential>

### Recommendations
- <commands to fix or replace>
- <reordering suggestions>
```

---

### Phase 6: Review — Deep Stress-Test Team

**Purpose:** Augment the built-in four-perspective review with deeper, evidence-based analysis.

| Agent | Subagent Type | Mission |
|-------|---------------|---------|
| **Edge Case Hunter** | Explore | Search the codebase for edge cases the blueprint doesn't handle — null states, race conditions, boundary values, error propagation paths. |
| **Regression Analyst** | Explore | Identify existing tests and functionality that could break from the proposed changes. Map the blast radius. |
| **Security Scanner** | general-purpose | Review the blueprint for OWASP top-10 vulnerabilities, auth gaps, injection risks, and data exposure. |

**Report format:**
```
## Deep Stress-Test Report

### Edge Cases
- Step N: <edge case description with file reference>
- ...

### Regression Risk
- <existing tests that may break>
- <functionality at risk>
- <blast radius assessment>

### Security Review
- <vulnerabilities found>
- <auth or access control gaps>
- <data handling concerns>

### Recommendations
- <steps to add or modify>
- <additional tests to include>
```

---

### Phase 7: Finalize — Plan Quality Team

**Purpose:** Final quality check on the plan file before it becomes the source of truth for Ralph Loop.

| Agent | Subagent Type | Mission |
|-------|---------------|---------|
| **Completeness Checker** | general-purpose | Verify every success criterion is testable, every step has a verification command, and no requirement from Phase 2 is missing. |

**Report format:**
```
## Plan Quality Report

### Coverage Check
- <requirements from Phase 2 mapped to steps>
- <gaps: requirements without coverage>

### Verification Completeness
- <steps missing verify commands>
- <success criteria that aren't testable>

### Recommendations
- <gaps to close before launch>
```

---

## How to Deploy

At any phase, the main Ralph Plan flow (or the user directly) can deploy agent teams by:

1. Identifying which phase agents are relevant
2. Launching them in parallel using the Task tool
3. Presenting the combined report to the user
4. Letting the user decide what to incorporate

**Example deployment (Phase 1):**
```
Task(subagent_type: "Explore", prompt: "You are the Stack Profiler agent. Map every dependency...")
Task(subagent_type: "Explore", prompt: "You are the Pattern Scout agent. Find architectural patterns...")
Task(subagent_type: "Bash", prompt: "You are the History Analyst agent. Analyze git history...")
```

All three run in parallel. Results are combined into the Codebase Recon Report.

## Deployment Protocol

1. **Announce:** Tell the user which agent team is being deployed and why
2. **Deploy:** Launch agents in parallel via Task tool
3. **Collect:** Wait for all agents to return
4. **Report:** Present the combined report with clear section headers
5. **Recommend:** Highlight the top 3 actionable findings
6. **Defer:** Ask the user what to incorporate — never auto-apply

The user always has final say. Agent teams inform; they never decide.
