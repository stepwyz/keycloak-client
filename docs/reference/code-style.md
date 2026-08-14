# Code style

> **Reference copy (2026-08-14):** pulled from TrueMeeting's `clio` (Rails API)
> as a convention guideline for the `keycloak-client` gem, and trimmed to what
> applies to a plain Ruby gem. Dropped from the original: default scopes and
> `SoftDeletable`, "reads are current by default", why-not-`enum`, persist-in-one-call,
> and the blueprint/service layout rules — all ActiveRecord or Rails-app concerns
> with no counterpart here. Examples have been adapted to this gem's domain.

---

## Static vocabularies are frozen symbol arrays

**A closed set of values this gem defines is `%i[...].freeze`, never
`%w[...]`.**

```ruby
# Correct
REQUIRED_ACTIONS = %i[verify_email update_password configure_totp].freeze

# Wrong
REQUIRED_ACTIONS = %w[verify_email update_password configure_totp].freeze
```

### Why symbols

A symbol reads as *an identifier we chose*, a string reads as *data that came
from somewhere*. The distinction is the point: when you see `:verify_email` you
know it is a name from a fixed list, and when you see `"admin-cli"` you know it
is content. Symbols are also immutable, deduplicated by the VM, and compared by
identity rather than by bytes.

The frozen array matters independently — without `.freeze` a caller can mutate
the vocabulary in place, and a constant that can be appended to is not a
controlled vocabulary.

### Multi-line when there is more than a handful

Two or three values stay on one line. Longer sets go one per line, so a diff
that adds a value touches one line:

```ruby
SCOPES = %i[
  users
  realms
  clients
  organizations
  roles
  groups
].freeze
```

---

## The string boundary

Keycloak's REST API speaks JSON. Request paths, query params, and response
bodies are strings. **Symbols live in Ruby; strings live at every edge.**
Convert explicitly at the boundary rather than letting one leak into the other.

This gem's `symbolize_json` middleware is exactly that conversion, applied once:
response bodies come back with symbol keys so callers write `user[:id]`, never
`user['id']`. Nothing downstream re-checks which it got.

### Values from other systems stay strings

The convention covers vocabularies **we** define. An identifier owned by
something else is data, and data is a string. Almost everything this gem handles
falls on that side of the line — realm names, client IDs, group paths, role
names, and user IDs are Keycloak's, not ours:

```ruby
# Keycloak owns these names; the symbol keys are ours.
GROUP_ROLES = { 'admins' => :admin, 'moderators' => :moderator }.freeze
```

The test is whether the set is ours to change. A UUID that came back from
Keycloak never becomes a symbol.

### Predicates: `&.to_sym`

Where a vocabulary of ours is compared against a value that may be nil, the
safe-navigation operator is not optional — `nil.to_sym` raises, while
`include?(nil)` is simply `false`, which is the answer you want:

```ruby
def mail_action?(action)
  MAIL_ACTIONS.include?(action&.to_sym)
end
```

---

## Naming a subset

When two or more call sites need the same slice of a vocabulary, name it rather
than spelling out the literal each time. An inline `%i[...]` inside a predicate
is a vocabulary hiding from the reader — it will not be found when someone greps
for where the vocabulary is used.

---

## Formatting

- **Single quotes** for strings unless interpolating (enforced by RuboCop —
  `Style/StringLiterals` is the one override in `.rubocop.yml`).
- **No comments in Ruby source.** Code carries no prose — not even "why"
  comments. Name things so the code reads, and put the reasoning that used to
  live inline into `docs/reference/`, where it can be found by someone who
  isn't already staring at the file.

  The only exceptions are comments the interpreter or a tool reads:
  magic comments (`# frozen_string_literal: true`) and directives
  (`# rubocop:disable …`).

  This is a real trade. Things like why a DELETE with a body has to be built by
  block, or why the send-email endpoints carry their own timeout, were
  discovered the hard way and are no longer written where you would trip over
  them. They live here instead — so **when you learn something the code cannot
  express, write it there.** A reference doc nobody updates is worse than the
  comments it replaced.
- Run `bundle exec rubocop` before committing; the config is
  `rubocop-rails-omakase`.
