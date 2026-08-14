# Error handling and boundary validation

> **Reference copy (2026-08-14):** pulled from TrueMeeting's `clio` (Rails API)
> as a convention guideline for the `keycloak-client` gem, and trimmed to what
> applies to a plain Ruby gem. Dropped from the original: model validations
> mirrored by DB constraints, the seed loader/verifier boundary, and the
> controller-side error renderer. The principle and the failure-handling rules
> carry over; the boundaries are different ones.

---

## The principle

**Validate at the boundary; trust the interior.**

A codebase gets its reliability from a small number of well-defended entry
points, not from a large number of scattered checks. When data crosses into the
system — a caller's arguments, an HTTP response from Keycloak, an env var — it is
parsed and validated *once*, at that boundary. Everything past the boundary
operates on data whose shape is already guaranteed, and is written as
straight-line code.

The smell this doc exists to prevent: a field is optional at the edge, so half a
dozen call sites each check whether it is nil before using it. Every one of those
checks is the same missing boundary validation, paid for repeatedly, each with
its own slightly different idea of what to do when the check fails. The fix is
never a seventh check — it is requiring the value at the boundary and deleting
the six.

A useful reframe: **parse, don't validate.** A validation inspects a value and
leaves it the same loosely-typed thing it was; a parse *transforms* it into a
richer type that cannot represent the invalid state. The `symbolize_json`
middleware is the house example — it does not check whether a response body
"looks symbolized" and pass the hash along; it converts once, on the way through,
and every caller downstream takes symbol keys and never wonders.

## What counts as a boundary in a client gem

| Boundary | Enforcement that lives there |
|---|---|
| Caller → `AdminClient` | Keyword arguments with explicit defaults, resolved once in `#initialize`. `@timeout` is settled at construction, not re-derived per request. |
| Config → client | `KeycloakClient.config` is read when the connection is built. Read and settle configuration at construction; don't consult it deep in a request path where a mid-flight change would half-apply. |
| Keycloak → gem | Faraday's `raise_error` middleware turns a non-2xx into a `Faraday::Error` at the edge of the stack, and `symbolize_json` normalizes the body. No resource method inspects `response.status`. |
| Gem → caller | Resource methods return parsed data or raise. A method that returns `nil` on failure forces every caller to re-check what the exception already said. |

If you are checking a value's presence or shape and you are *not* at one of these
boundaries, that is the signal to move the check to the boundary instead.

## Nil with meaning vs. nil from negligence

Not all nils are defects. A Keycloak API that omits a field is often saying
something specific, and those nils deserve handling — once, with the meaning
named:

- A `location` header absent from a create response = **the server did not
  assign an ID we can return**.
- An optional query param left nil = **not filtering on it** — which is why
  `params.compact` is applied before the query string is built, rather than each
  caller pruning its own hash.

The test: can you name the state the nil represents? Then handle it where that
state matters, ideally through a named predicate rather than a raw nil check —
the name is the documentation. If the only honest name is "someone forgot to
require this," it is negligence-nil: make the keyword argument required and
delete the checks.

## The concrete example, worked

The anti-pattern — an optional-argument cascade:

```ruby
# The client doesn't settle a timeout…
def initialize(timeout: nil)
  @timeout = timeout
end

# …so every consumer defends itself:
@timeout || KeycloakClient.config.timeout        # in the connection builder
(@timeout || 10) * 2                             # in a retry helper
return unless @timeout                           # in a predicate
```

Fix at the boundary, then write the interior straight:

```ruby
def initialize(timeout: nil)
  @timeout = timeout || KeycloakClient.config.timeout
end
```

Now `@timeout` is an Integer everywhere, unconditionally. If a nil ever gets
through, it raises at the first use — loudly, near the cause — instead of flowing
silently through six guards and surfacing as an unbounded request three layers
away. **A crash close to the bug beats a soft failure far from it.**

## Failure handling rules

1. **Raise specific, rescue specific, rescue rarely.** A `rescue` clause is a
   claim that *this* code can meaningfully act on *that* error. Bare
   `rescue => e` (or `rescue nil`) converts a loud failure near the cause into a
   quiet corruption far from it. A client gem in particular should let
   `Faraday::Error` reach the caller — the host application knows whether a
   404 on a user lookup is fatal, and this gem does not.
2. **Don't log-and-continue.** Logging an error and proceeding is rescuing
   without acting. If the operation cannot succeed, fail the operation; if it
   can succeed without the failed part, that is a named, deliberate degradation
   — not a swallowed exception.
3. **No fallback values that impersonate data.** `value || default` is correct
   only when the default is a real domain value (`timeout || config.timeout`).
   When the default exists to keep broken code moving — an empty array standing
   in for a failed list call — it converts a detectable bug into an undetectable
   lie.
4. **Non-idempotent calls deserve room to finish.** A timeout that fires after
   the server has already acted turns a success into a reported failure, and a
   retry into a duplicate. The send-email endpoints carry their own longer
   timeout for exactly this reason. Before tightening a bound, ask what a
   spurious `Faraday::TimeoutError` would cost the caller.
5. **Errors cross the API in one shape.** Faraday's own error hierarchy is that
   shape. New code adds new error *conditions*, never new error *shapes* — a
   bespoke `KeycloakClient::NotFound` wrapping a `Faraday::ResourceNotFound`
   gives the caller two things to rescue and no new information.

## Where defensiveness is correct

Defensive code is the *right* tool exactly at the boundaries facing data we do
not control:

- **Responses.** Keycloak's admin API is loosely specified in places — a field
  present on one version and absent on the next, a create that returns a body on
  some endpoints and a bare `location` header on others. Parse defensively where
  the response is read, emit a settled shape, and keep the defensiveness *there*
  rather than in every caller.
- **Version drift.** Behaviour that differs across Keycloak releases belongs
  behind one named method, not spread as inline conditionals at each call site.

## Review checklist (the smells)

- The same presence/shape check on the same value in more than one place.
- `&.` / `try` / `dig` on data that already crossed a validated boundary.
- `rescue => e` broader than the error the code can act on; any `rescue nil`.
- A logged error followed by `next`/`return` with no state change.
- `|| fallback` where the fallback is not a citable domain value.
- A resource method that returns `nil` to mean "the request failed".
- An optional keyword argument whose nil has no nameable meaning.
- A timeout or retry bound applied to a non-idempotent call without a reason.

RuboCop's `Lint/SuppressedException` covers part of this mechanically; prefer
enforcement over review comments where a cop exists.
