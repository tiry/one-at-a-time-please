# Worked examples

## 1. Two options that change code shape (A/B samples)

### Context block (plain text, sent first)

```
## (2 of 5) API client: how failures are reported

Decided so far: single `ApiClient` class in `src/api/client.ts`, callers
in `src/features/*`. This choice shapes all ~12 call sites and the global
error boundary in `src/app/ErrorBoundary.tsx`.

A — throw typed errors
    const user = await api.getUser(id); // throws ApiError
  Callers stay short; failures surface via try/catch or the boundary.

B — return a Result
    const r = await api.getUser(id);
    if (!r.ok) return handle(r.error);
  Explicit at every call site; no hidden control flow, more boilerplate.

Recommended: A
Why: the codebase already has a global error boundary; B would duplicate
handling at every call site.
```

### `question` tool call (one question only)

```json
{
  "questions": [
    {
      "header": "API errors",
      "question": "(2 of 5) How should the API client report failures?",
      "options": [
        { "label": "Throw typed errors (Recommended)", "description": "Matches the existing error boundary" },
        { "label": "Return a Result type", "description": "Explicit handling at each call site" }
      ]
    }
  ]
}
```

### If the user replies in free text

User: "why not both?"

Answer (e.g. the cost of maintaining two styles), then call `question`
again with the same options. Record only once the user picks.

User: "whatever you think"

Not a decision. Re-ask with the two concrete options.

### After the choice

`Recorded: API errors → Throw typed errors`

…and an entry is appended to `docs/decisions.md`.

## 2. Topology question (ASCII diagram instead of code)

```
## (3 of 5) Webhook delivery: inline or queued?

OrderService.markShipped() is synchronous today and already makes one
external call:

  markShipped()
    ├─ update DB
    └─ send email (sync, ~200 ms p95)

Inline webhooks add N HTTP calls on the request path; receivers can be
slow or down.

A — inline in markShipped()
B — enqueue (Sidekiq), deliver async with retries

Recommended: B
Why: Sidekiq is already used for the label PDF; same shape, same retry
semantics. Inline couples ship latency to third parties.
```

Then one `question` call with "Enqueue (Recommended)" and "Inline".

## 3. Yes/no is still a `question` call

Wrong (plain text, does not wait):

> "Shall I proceed with the migration? (yes/no)"

Right: `question` with options `Proceed (Recommended)` / `Cancel`.
