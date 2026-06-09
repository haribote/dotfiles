---
name: call-code-critic
description: "WHEN: the user wants a critical review by the `code-critic` agent. The skill gathers the agent's required Invocation Contract inputs (review target, intent, layer), dispatches the agent via the Agent tool, and drives the **address-then-resubmit** loop until the agent returns an `Approved` verdict or the user explicitly defers what is left."
user-invocable: true
---

## Role

Entry seam between the user and the `code-critic` agent, **and owner of the review submission loop**. Model the cycle on a GitHub PR review:

1. Gather the four Invocation Contract inputs and **request a review** (dispatch the agent).
2. Drive the **address-then-resubmit** loop. Each agent return is a **review submission** with a single-line verdict (`Approved` or `Request changes`). Iterate until the verdict is `Approved`, or the user explicitly defers what remains. A single submission is **not** a complete review.

All review logic—Review Layering, foundational lenses, the choice between `critic-design-review` and `critic-implementation-review`—lives **inside the agent**. The skill never critiques. But it owns the cycle—line comments without follow-through are wasted output.

## Procedure

### 1. Gather the agent's required inputs

From the user (via `AskUserQuestion` if missing):

- **Code under review**: file paths, directory, diff, PR number, or pasted code—each in identifiable scope
- **Intent of the change**: what it accomplishes; for design review, the design intent and constraints; for implementation review, the contract / signature / invariants to satisfy
- **Review layer in scope**: `design` / `implementation` / `both` / `unspecified`

From the **host agent's own context** (do not ask the user):

- **Workspace root for persistence**: absolute path of the Claude Code session's primary working directory. The host agent knows this from its system context. In a multi-project workspace, the user's intended workspace root may be an ancestor of the review target; pass the **ancestor**, not the review target. Resolve and validate this absolute path **once, in this skill, before launching the agent**. The Invocation Contract requires the caller to supply the path explicitly; the agent refuses if it is missing.

### 2. Request the initial review

Call the `Agent` tool with `subagent_type: code-critic`. Pass the four items in this structure:

```
## Code under review
<file paths / diff / PR number / pasted code, with identifiable scope>

## Intent of the change
<what the change accomplishes; for design review, the design intent and constraints;
 for implementation review, the contract / signature / invariants to satisfy>

## Review layer in scope
design | implementation | both | unspecified

## Workspace root for persistence
<absolute path of the Claude Code session's primary working directory>
```

Pass `description: Critical review via code-critic` and optionally `name: code-critic-<branch-slug>`.

**Capture the agent's ID** from the response (`agentId: <id>` / `SendMessage with to: '<id>'`). This ID is the handle for every resubmission—do not lose it.

### 3. Drive the address-then-resubmit loop (mandatory)

Each agent return is a **review submission** beginning with a verdict line:

- `Approved` — no blockers. **Loop terminates.** No file is persisted by the agent. Surface the verdict to the user and stop the loop.
- `Request changes` — one or more line-comment blockers, persisted to `tmp/code-critic-<branch-slug>-<rev>.md`. Continue with steps below.

For a `Request changes` submission:

1. **Surface the agent's verdict and line comments to the user verbatim** (`Issue / Root Cause / Impact / Fix`). Every line comment is a blocker—do not summarize, rank, or soften. Note the persisted file path (`Review saved to: <path>`).
2. **Triage with the user** for each thread via `AskUserQuestion`. Triage is binary:
   - **Address**: apply the structural fix the agent prescribed. Commit if appropriate.
   - **Reject (with reason)**: only when the user provides a domain reason that makes the thread non-applicable. "Later" or "minor" is **not** a reason.
3. **Apply the addressed fixes**.
4. **Resubmit via `SendMessage` against the captured agent ID**—do **not** re-launch a fresh `Agent`. Resuming preserves the agent's working memory of the prior submission. Message body focuses on the delta:

   ```
   ## Resubmission addressing <prior file path>

   ## Workspace root for persistence
   <same absolute path passed at initial dispatch>

   ## Changes since prior submission
   <diff, paths, or summary referencing the prior threads>

   ## User decisions on prior threads
   - <prior thread title> → Address (fix applied as: <one-line summary>)
   - <prior thread title> → Reject (reason: <user-supplied domain reason>)
   ```

   The agent reconciles open threads against the latest persisted file, applies its principles to the delta, and returns the next submission—either `Approved` (terminate) or `Request changes` with `code-critic-<branch-slug>-<rev+1>.md` (loop continues).

   **Fallback**: if the agent ID is no longer addressable, launch a fresh `Agent` as in step 2, expanding `Intent of the change` with the resubmission context and the prior file path. The agent's `Reconcile prior threads` will still work via the persisted file; in-conversation memory is lost—accept only as fallback.

**Termination condition** (loop exits when **either** holds):

- The agent returns the `Approved` verdict (no open threads, no new blockers).
- Every open thread from the latest `Request changes` submission has a recorded user outcome (Address with fix applied, or Reject with explicit user-supplied reason).

There is no "deferred" state. The upstream contract guarantees every line comment is a blocker.

When the loop exits, summarize the final state to the user: which submissions ran, which threads were addressed, which were rejected (with reasons), and—if applicable—the path of the latest persisted submission. If the terminal verdict is `Approved`, state that explicitly.

## Constraints

- The skill **gathers, dispatches, and drives the submission loop**. It does not critique or shape the agent's output.
- A single submission is **not** a complete review. Exiting after one pass without either an `Approved` verdict or a recorded user decision per thread is a contract violation.
- The user owns the Address / Reject decision for each thread. Do not auto-defer or auto-reject.
- Apply structural fixes (per the agent's `Fix` text), not surface-level textual patches.
- **Capture the initial agent ID** and use `SendMessage` for every resubmission. Re-launching per submission is wasteful; only fall back if the captured ID is no longer addressable.
