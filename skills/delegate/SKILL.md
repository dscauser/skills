---
name: delegate
description: Use when running Claude Opus 5.5 on codebase-heavy or token-heavy work and the user wants Opus to orchestrate research, coding, and testing while Sonnet 5.5 subagents (medium or high effort) do bounded heavy lifting. Also use when the user says "delegate", "use subagents", or "use sonnet for the grunt work".
---

# Delegate

Use Claude Opus 5.5 (the main session) as the orchestrator, architect,
synthesizer, and final judge. Use Sonnet 5.5 subagents, at medium or high
effort, for token-heavy research, coding, testing, and summarization that do
not require Opus's full judgment.

## How to Spawn the Subagents (no research needed)

Two global subagent definitions exist for this skill:

| `subagent_type` | Model | Effort | File |
|---|---|---|---|
| `sonnet-medium` | `sonnet` (Sonnet 5.5) | `medium` | `~/.claude/agents/sonnet-medium.md` |
| `sonnet-high` | `sonnet` (Sonnet 5.5) | `high` | `~/.claude/agents/sonnet-high.md` |

Call them with the Agent tool:

```
Agent(
  description: "Map auth call sites",        # 3-5 words
  subagent_type: "sonnet-medium",             # or "sonnet-high"
  prompt: "<handoff packet — see below>",
  run_in_background: true                     # default; false only if your very next step needs the result
)
```

Facts about the harness that shape this:

- **Effort cannot be passed at call time.** The Agent tool has no effort
  parameter. Effort comes only from the `effort:` frontmatter field of the
  agent definition (`low | medium | high | xhigh | max`). That is why the two
  named agent types exist. Pick effort by picking `subagent_type`.
- **Model can be passed at call time** (`model: "sonnet" | "opus" | "haiku" |
  "fable"`) and overrides the definition. Do not pass `model` with these two
  agents. Their definitions already set `sonnet`.
- Model resolution order: the call's `model` param, then the agent's `model:`
  frontmatter, then the `CLAUDE_CODE_SUBAGENT_MODEL` env var, then the main
  session's model.
- The built-in agent types (`general-purpose`, `Explore`, `Plan`) inherit
  session effort, so they do not give controlled effort. Use the two above
  instead.
- Launch independent subagents **in a single message with multiple Agent
  calls** so they run concurrently.
- Background agents re-invoke you when they finish. Do not poll or sleep. Do
  not predict or invent their results while they are still running.
- To follow up with a finished agent with its context intact, use
  `SendMessage` to its agent ID. A new Agent call starts fresh.
- The subagent's report is not shown to the user. Relay what matters.
- For write-heavy parallel edits that could collide, pass
  `isolation: "worktree"` so each agent works on its own git worktree copy.
- The agent files ship in the `agents/` folder of the
  [`dscauser/skills`](https://github.com/dscauser/skills) repository, and its
  install script puts them in `~/.claude/agents`. If either is missing and the
  repo is not available, recreate it as `~/.claude/agents/<name>.md`:

  ```yaml
  ---
  name: sonnet-high
  description: Sonnet 5.5 worker at high effort for delegated work that needs real reasoning.
  model: sonnet
  effort: high
  ---
  <short worker instructions: stay in scope, stop-and-report, return evidence>
  ```

## Choosing Medium vs High

**`sonnet-medium`**: well-specified work where the path is obvious:

- Repo searches, file and symbol inventories, "where is X used".
- Doc, API, and prior-art scans that return summaries.
- Running test suites or builds and reducing the output to the failures.
- Log clustering and noise reduction.
- Mechanical or narrow edits: renames, boilerplate, applying a known pattern
  across files, small isolated fixes.
- Browser/screenshot passes that follow an explicit script.

**`sonnet-high`**: bounded work that still needs real reasoning:

- Multi-file code changes or candidate patches for a designed approach.
- Bug hunts, reproducing issues, root-cause debugging.
- Diagnosing test failures (flaky vs environmental vs real).
- Research synthesis where sources conflict or the answer is not a lookup.
- Writing new tests that have to exercise tricky behavior.

If unsure, start with `sonnet-medium`. Escalate to `sonnet-high` (or take the
task back into Opus) if the medium report is shallow, wrong, or hits its stop
conditions.

## Where Opus Shines

Reserve Opus for:

- Decomposing ambiguous work into clean parallel slices.
- Architecture, product, and safety tradeoffs.
- Reading conflicting subagent reports and deciding what matters.
- Integrating partial implementations into one coherent plan.
- Final review, risk assessment, and user-facing synthesis.

## Delegation Pattern

1. Name the expensive-token risk: large repo search, long logs, broad docs, or
   repetitive edits.
2. Split independent work into subagents before reading everything yourself.
3. Route each slice to `sonnet-medium` or `sonnet-high` using the guide above.
4. Ask subagents for concise evidence: files, line references, commands run,
   diffs, uncertainties, and stop conditions they hit.
5. Spend Opus tokens on the decision layer: compare results, resolve
   conflicts, choose the implementation path, and review the final patch.

Prefer parallel subagents when the slices do not depend on each other. Keep
blocking or highly coupled work local.

## Handoff Packets

Write delegated prompts as if the subagent has no useful chat context, because
it has none. Include only the context it needs:

- The repo path and exact objective.
- The files, packages, or surfaces in scope and anything explicitly out of
  scope.
- The evidence format to return: files, line refs, commands, diffs, failures,
  screenshots, and uncertainty.
- The verification commands or browser flows to run, plus what success should
  look like when that is knowable.
- Stop conditions: if the code does not match the prompt, a command fails after
  a reasonable retry, or the task needs out-of-scope files, stop and report
  instead of improvising.

## Vetting Delegated Work

Treat subagent reports as leads, not facts. Before using a high-impact finding,
opening a PR, or telling the user the work is done, Opus should reopen the
important cited files, confirm the relevant line refs or failures, and review
the final diff against the task. Let the Sonnet agents gather signal. Keep
truth-judgment with Opus.

## Common Scenarios

Treat these as soft defaults, not rigid rules:

- Research: `sonnet-medium` scans docs, prior art, APIs, and repo surfaces;
  `sonnet-high` when sources conflict or synthesis is needed. Opus decides
  what evidence changes the plan.
- Coding: `sonnet-medium` for mechanical edits, `sonnet-high` for bounded
  multi-file patches. Opus owns shared-file coordination, integration, and
  final review.
- Testing: Opus sets the validation direction and picks the scripts or browser
  checks that matter. `sonnet-medium` runs targeted tests, browser flows,
  screenshots, and log reduction. `sonnet-high` diagnoses failures and
  reports exact commands, failures, likely causes, and whether failures look
  flaky, environmental, or real.
- Debugging: `sonnet-medium` clusters logs, `sonnet-high` reproduces issues
  and tries small fixes. Opus decides which diagnosis is most trustworthy.

If a task is tiny, or the validation itself needs delicate judgment, keep it
with Opus. Spawning a subagent has overhead, so don't delegate a single grep
or a one-line edit.

## Expectations

For codebase-heavy work, this can plausibly be several times more
cost-efficient and faster when independent research, coding, or testing
slices run in parallel. These are workload-dependent estimates, not
guarantees.
