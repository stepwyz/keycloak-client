# RSpec and testing guidelines

> **Reference copy (2026-08-14):** pulled from TrueMeeting's `clio` (Rails API) —
> which took it from the bxhealth `erebus` backend — as a convention guideline for
> the `keycloak-client` gem, and trimmed to what applies to a plain Ruby gem.
> Dropped from the original: seed data and `default_context`, FactoryBot, `db:reset`
> / `parallel_tests`, Active Storage analyzers, and the request/blueprint matchers
> (`respond_with_status_code`, `respond_with_error`) — none of which exist here.
> The spec-style rules and the `ExpectationsHelper` helpers carry over intact;
> `spec/support/expectations_helper.rb` in this repo is the same file.

## Layout

- Unit specs mirror the `lib/` structure under `spec/keycloak-client/`
- Integration specs live in `spec/integration/`, one file per resource module
- Shared helpers live in `spec/support/` and are loaded by `spec_helper.rb`:
  `ExpectationsHelper`, `AdminClientBuilder`, `KeycloakBootstrap`, SimpleCov wiring

## Running the suite

Unit specs only, no external dependencies:

```sh
bundle exec rspec
```

Integration specs are tagged `:integration` and excluded by default because they
require a live Keycloak. Include them with `KC_LIVE=1` — or `rake integration`,
which sets it for you — and `KeycloakBootstrap.run!` provisions a fresh test
realm in `before(:suite)`:

```sh
docker compose up -d
bundle exec rake integration
```

A spec that reaches the network without an `:integration` tag is a defect: it
makes the default run depend on a container being up.

## Spec style

`describe` and `context` have distinct roles:

- **`describe`** — identifies the method under test. Always pair it with a `subject {}` block.
- **`context`** — describes a condition or variation. Always start the description with `when`.

This separation makes the suite easy to read ("what is being tested, and under
what conditions?") and scales cleanly with nesting.

```ruby
RSpec.describe KeycloakClient::AdminClient do
  describe '#for_realm' do
    subject { client.for_realm('other') { client.current_realm } }

    let(:client) { described_class.new(realm: 'master') }

    it { is_expected.to eq('other') }

    context 'when the block raises' do
      subject { client.for_realm('other') { raise 'boom' } }

      it { is_anticipated.to raise_error('boom') }
      it { will_with_error; expect(client.current_realm).to eq('master') }
    end
  end
end
```

Use `is_anticipated` (from `ExpectationsHelper`) as shorthand for `expect { subject }`:

```ruby
it { is_anticipated.to change { KeycloakClient.config.timeout }.to(20) }
it { is_anticipated.to_not raise_error }
```

This pattern also supports TDD: when reproducing a reported bug, write a
`context` that matches the failing condition first, then fix the code to make it
pass.

### One-liners when the subject has to be invoked first

`is_expected` and `is_anticipated` trigger `subject` themselves, so an assertion
about the **return value** needs no help. An assertion about a **side effect** —
a request the call made, state it mutated — has to invoke the subject and then
look somewhere else. That used to force a named multi-line example whose
description merely restated the matcher:

```ruby
# Avoid — the description says nothing the assertion doesn't
it 'raises the timeout on the mail endpoint' do
  subject
  expect(request.options.timeout).to eq(30)
end
```

`will` invokes the subject, so the example collapses to one line and the
redundant description disappears:

```ruby
it { will; expect(request.options.timeout).to eq(30) }
```

The four helpers, all from `spec/support/expectations_helper.rb`:

| Helper | Order | Reach for it when |
|---|---|---|
| `will` | block if given, then `subject` | invoking the subject inline — bare `will;` — or running setup immediately before it |
| `does` | `subject`, then block | invoking, then asserting inside the block |
| `will_with_error` | like `will`, swallowing `StandardError` | the subject raises and the assertion is about what survived it |
| `is_anticipated_with_error` | `expect { subject rescue … }` | wrapping a raising subject in a `change` matcher |

**Keep the named example when the name earns its place.** A description that
states something the matcher cannot — why an outcome matters, a non-obvious
invariant, the reason a case exists at all — is not redundant, and collapsing it
loses information a reader wanted. Two or more assertions in one body is usually
the same signal: name it. The rule deletes descriptions that paraphrase the
assertion; it does not ban multi-line examples.

## What to test (and what not to)

**Avoid loops in specs where you can.** Iterating a list of values to generate
examples (`%w[...].each do |value| ... end`) obscures intent and bloats the run
with near-identical cases. Prefer a small number of explicit `context`s —
typically one representative valid case and one invalid case — over enumerating
every permitted value.

This is a default, not an absolute — a genuinely table-driven case (a matrix of
input/output pairs that would be tedious and error-prone to spell out) can still
justify a loop. Reach for it deliberately, not reflexively.

**Don't exhaustively test Faraday.** Faraday and its adapters are well-tested —
we don't need to re-verify that a timeout option reaches the socket or that the
`raise_error` middleware raises on a 404. Run *a* test that confirms we wired the
feature up correctly (the option lands on the connection, the middleware is in
the stack) and move on. Spend test effort on *our* logic and the contract our
callers depend on.

**Unit specs assert on what the client builds; integration specs assert on what
Keycloak does.** Path construction, realm scoping, request options, and response
shaping are all checkable without a server — that is where the fast suite earns
its keep. Whether Keycloak actually accepts the payload is exactly what
`spec/integration/` is for, and duplicating it in a mocked unit spec proves only
that the mock agrees with itself.
