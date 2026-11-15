---
name: one-at-a-time
description: Use whenever you have 2 or more open questions, clarifications, or design decisions for the user. Shows an agenda, then walks through ONE question at a time with context, a recommendation, optional discussion, and a recorded decision. Never dump a list of questions.
---

# One At A Time

The user should never be asked to answer a wall of questions. Each decision
gets its own context, a recommendation, a chance to discuss, and an
explicit record.

## Phase 0 — Ground first

Before asking anything:

- Read the relevant code, docs, and links. **If a question can be answered
  by reading, read instead of asking.**
- Read `docs/decisions.md` if it exists. **Never reopen a recorded decision
  and never ask what the project or the conversation already answers.**
- Map the decision space: which answers constrain which other questions.

## Phase 1 — Agenda (plain text, no tool call)

List every remaining open question as a numbered table, one line each:

| # | Topic | Why it matters / what it blocks |
|---|-------|---------------------------------|

Order by dependency: **roots first** (answers that constrain other
questions), then depth-first within a branch. End with "Starting with #1."
Do not ask anything yet.

## Phase 2 — One question at a time

Repeat for each agenda item.

### 1. Context block (plain text, sent before the tool call)

Use exactly this shape:

```
## (n of N) <Short question label>

<Context overview, 1–4 sentences: where in the design we are, what is
already decided, what this depends on, which files/components it touches.
If the question is about topology, flow, or relationships, add a small
ASCII diagram here.>

<Options, 2–4 max. If there are exactly two and the choice changes code
shape, show a short code sample for each, labelled A and B, under ~15
lines, only the part that differs. See references/two-option-example.md.>

Recommended: <one option, one sentence>
Why: <1–2 sentences>
```

Terse prose. No throat-clearing. Do not restate what was just decided.

### 2. Ask with the `question` tool

- **Never ask in plain text when the answer can be expressed as options.**
  A text question does not wait for an answer; the tool does. This
  includes yes/no: use options like "Proceed" / "Cancel" instead.
- Exactly ONE question per call. The tool accepts an array; use one element.
- `header`: the question label (≤ 30 chars).
- `question`: the one concrete question, starting with `(n of N)`.
- Options mirror the context block. Each option needs a `label` (1–5
  words) and a `description` (one line; the tool requires both).
  Recommended option first, label suffixed with ` (Recommended)`.
- Leave `custom` enabled so the user can answer in free text. Do not add
  an "Other" option yourself.

### 3. Discuss before recording

If the answer is free text that is a question, an objection, a "what if",
or a request for more detail: answer it, revise the context if needed, and
ask the same question again. Record nothing yet.

These are **not** decisions either; re-ask with two concrete options:
"whatever you think", "sounds good", "sure", "you decide".

Loop until the user picks an option or clearly states a choice.

### 4. Record

- Append an entry to `docs/decisions.md` (create it if missing) using
  `references/decision-template.md`.
- Echo one line: `Recorded: <topic> → <choice>`.

### 5. Re-plan

- Skip later items whose answers are now implied; say so.
- If a decision raises a new question, add it to the agenda; say so.
- If the user changes an earlier answer, recheck what it invalidates.

### 6. Play it back

Every 3–4 recorded decisions, or when one branch of the design is fully
settled, describe that part back in a short paragraph (what it is, how it
behaves) before moving to the next item. Only what the user chose goes in
as theirs; anything you filled in is marked as your proposal.

## Phase 3 — Wrap-up

Stop when all items with material consequences are resolved, or when the
user says they have enough. Print the final table (topic → choice) plus any
deliberately deferred items, then continue the task.

## Anti-patterns

- Asking multiple questions in one turn or one `question` call.
- Asking in plain text and continuing to work.
- Asking without a context overview.
- Asking without a recommendation.
- Asking what the codebase, the conversation, or `docs/decisions.md`
  already answers.
- Recording a decision while the user is still discussing it.
- Prose where an ASCII diagram or a 5-line code sample would be faster.
- Continuing past useful resolution.
