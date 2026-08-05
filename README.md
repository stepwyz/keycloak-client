# KeycloakClient

A Ruby client for the [Keycloak](https://www.keycloak.org/) Admin REST API
(Keycloak 24 and newer).

It wraps the admin endpoints for realms, users, clients, client scopes, roles,
groups, and organizations behind a single `KeycloakClient::AdminClient`, and
handles token acquisition and refresh for you.

## Installation

The gem is not published to RubyGems yet. Install it from git:

```ruby
# Gemfile
gem 'keycloak-client', github: 'stepwyz/keycloak-client'
```

then

```bash
bundle install
```

Requires Ruby >= 3.0.

## Configuration

```ruby
KeycloakClient.configure do |config|
  config.host          = ENV.fetch('KEYCLOAK_HOST')          # e.g. https://auth.example.com
  config.realm         = ENV.fetch('KEYCLOAK_REALM')         # default realm for new clients
  config.client_id     = ENV.fetch('KEYCLOAK_CLIENT_ID')     # service-account client
  config.client_secret = ENV.fetch('KEYCLOAK_CLIENT_SECRET')
end
```

Each setting falls back to the matching `KEYCLOAK_*` env var when the block
leaves it unset. In a Rails app, put the block in an initializer.

## Usage

`AdminClient` supports the two auth modes Keycloak offers for admin access.

**Service account** (`client_credentials`) — uses the configured
`client_id`/`client_secret`:

```ruby
admin = KeycloakClient::AdminClient.new
```

**Username/password** — uses the built-in `admin-cli` client against a realm
admin user:

```ruby
admin = KeycloakClient::AdminClient.new(
  realm: 'my-realm',
  username: 'realm-admin',
  password: 'secret'
)
```

Either way the client authorizes lazily on the first request and re-authorizes
when the token is within 30 seconds of expiry, so you rarely need to call
`authorize!` yourself.

```ruby
admin.create_user(username: 'ada', email: 'ada@example.com', enabled: true)

# Keycloak returns the new id in a Location header the client doesn't expose,
# so read the record back to get it.
user = admin.users(username: 'ada', exact: true).first
admin.send_verify_email(user[:id])

admin.groups
admin.add_group_member(group_id, user[:id])

admin.clients
admin.assign_client_role(role, client_id: client_uuid, user_id: user[:id])
```

Responses are parsed JSON with symbolized keys — hashes and arrays, not wrapper
objects. Endpoints that return no body (creates, updates, deletes) give you an
empty string.

### Working across realms

The client is scoped to one realm, but `for_realm` temporarily retargets it.
Note that the auth token is still minted against the realm the client was
constructed with, so the credentials must be allowed to administer the target
realm (a master-realm admin, typically):

```ruby
admin = KeycloakClient::AdminClient.new(realm: 'master', username: 'admin', password: 'admin')

admin.create_realm(realm: 'tenant-a', enabled: true)
admin.for_realm('tenant-a') do
  admin.create_user(username: 'ada', enabled: true)
end
```

### Available resources

| Module | Highlights |
|---|---|
| `Resources::Realms` | `realms`, `realm`, `create_realm`, `update_realm`, `delete_realm` |
| `Resources::Users` | CRUD, credentials, sessions, consents, federated identities, email actions, user profile |
| `Resources::Clients` | CRUD, secrets, service-account user, sessions, cluster nodes |
| `Resources::ClientScopes` | `client_scopes`, `create_client_scope`, default/optional scope assignment |
| `Resources::Roles` | realm and client roles, composites, assignment to users |
| `Resources::Groups` | CRUD, subgroups, lookup by path, membership, management permissions |
| `Resources::Organizations` | CRUD, members, invitations, identity-provider links |

All of them are mixed into `AdminClient`, so every method is called directly on
the client instance.

### Errors and raw requests

Faraday's `raise_error` middleware is enabled, so non-2xx responses raise
`Faraday::Error` subclasses (`Faraday::ResourceNotFound`,
`Faraday::UnauthorizedError`, and so on).

For endpoints the gem doesn't cover, the HTTP helpers are public and apply the
same realm scoping, `/admin` prefixing, and token handling:

```ruby
admin.get('/authentication/flows')
admin.post('/authentication/flows', { alias: 'custom-flow' })
admin.get('/.well-known/openid-configuration', {}, {}, admin_scoped: false)
```

Brace the body hash on `post`/`put`/`delete`: they take keyword arguments of
their own (`params:`, `body:`, `admin_scoped:`), so a bare `key: value` list is
parsed as keywords rather than as the body.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run
`rake spec` to run the unit tests, or `bin/console` for an interactive prompt.

To install the gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, then run
`bundle exec rake release`, which creates a git tag, pushes commits and the
tag, and pushes the `.gem` file to [rubygems.org](https://rubygems.org).

### Live integration testing

The repo ships with an integration suite (`spec/integration/*_spec.rb`) that
exercises the client against a real Keycloak server. Specs are tagged
`:integration` and are excluded unless `KC_LIVE=1` is set; the rake tasks below
set it for you.

Bring up a disposable Keycloak via the bundled `docker-compose.yml`:

```bash
docker compose up -d
```

That publishes Keycloak on `http://localhost:8080` with admin credentials
`admin` / `admin`. Set `KEYCLOAK_HOST_PORT` to use a different host port, and
point the suite at it with `KEYCLOAK_HOST`:

```bash
KEYCLOAK_HOST_PORT=8082 docker compose up -d
KEYCLOAK_HOST=http://localhost:8082 bundle exec rake integration
```

Tear it down with `docker compose down` (add `-v` to drop the Postgres volume).

#### Both auth modes

`rake integration` runs the suite twice, once under each auth mode supported by
`AdminClient#authorize!`:

```bash
bundle exec rake integration
```

- `integration:password` — admin username/password against an in-realm admin
  user
- `integration:service` — service account via `client_credentials` against a
  confidential client

#### A single auth mode

Run one mode on its own with the corresponding task:

```bash
bundle exec rake integration:password
bundle exec rake integration:service
```

Or drive RSpec directly, which is the easier route when you want to run a
single file or example. Set both `KC_LIVE` and `KC_AUTH` yourself:

```bash
KC_LIVE=1 KC_AUTH=password bundle exec rspec spec/integration/users_spec.rb
KC_LIVE=1 KC_AUTH=service  bundle exec rspec spec/integration --tag ~master_admin
```

`KC_AUTH` defaults to `password` when unset.

#### Bootstrap and fixtures

A `before(:suite)` hook in `spec_helper.rb` runs
`spec/support/keycloak_bootstrap.rb`, which drops and recreates a throwaway
realm (`keycloak-client-test`) on every run and provisions:

- `test-admin` / `test-admin-password` — realm-admin user used by the password
  mode
- `integration-suite` confidential client (secret `integration-suite-secret`)
  with `realm-admin` granted to its service account, used by the service mode

Cross-realm tests in `spec/integration/realms_spec.rb` are tagged
`:master_admin` and use the master-realm `admin`/`admin` user. The
`integration:service` task skips them automatically, since the service account
only has rights inside the test realm; add `--tag ~master_admin` when running
service mode through RSpec directly.

#### Environment variables

All of these are optional in non-live mode:

| Variable | Default |
|---|---|
| `KEYCLOAK_HOST` | `http://localhost:8080` |
| `KEYCLOAK_REALM` | `master` |
| `KEYCLOAK_CLIENT_ID` | `admin-cli` |
| `KEYCLOAK_CLIENT_SECRET` | `` |
| `KC_LIVE` | unset — set to `1` to include the `:integration` specs |
| `KC_AUTH` | `password` — `password` or `service` |
| `COVERAGE` | unset — set to `1` to enable SimpleCov |
| `COVERAGE_MIN` | `99` — minimum merged line coverage enforced by `rake coverage` |
| `KEYCLOAK_HOST_PORT` (compose only) | `8080` |
| `KEYCLOAK_SMTP_PASSWORD` (integration only) | unset — when set, the bootstrap configures the test realm's SMTP server so specs that send email (e.g. `Organizations#invite_existing_user`) can succeed instead of skipping. `KEYCLOAK_SMTP_HOST/PORT/USER/FROM` further override defaults (`smtp-relay.gmail.com:587`, `dan@stepwyz.com`, `hello@stepwyz.com`). |

Local overrides go in `.env.local` or `.env`; both are loaded by
`spec_helper.rb` via dotenv.

### Coverage

SimpleCov is wired up but opt-in, since a meaningful number needs the live
integration suite — the unit specs on their own exercise very little of the
gem. Bring up Keycloak first, then:

```bash
bundle exec rake coverage
```

That wipes `coverage/`, runs the unit suite plus both integration modes with
`COVERAGE=1`, merges the three runs into one report at `coverage/index.html`,
and fails the task if merged line coverage drops below 99% (override with
`COVERAGE_MIN`). Branch coverage is measured and reported but not enforced.

The one line the suite can't reach is `update_group_management_permissions`,
which needs Keycloak's `admin-fine-grained-authz` preview feature; its spec
skips when the feature is off. A few more are covered only when
`KEYCLOAK_SMTP_PASSWORD` is set, so expect a lower number without it.

To collect coverage for a single run instead, set `COVERAGE=1` on any rspec or
rake invocation:

```bash
COVERAGE=1 KC_LIVE=1 KC_AUTH=password bundle exec rspec spec/integration/users_spec.rb
```

Each process writes under its own command name (`unit`,
`integration-password`, `integration-service`) and merges into the shared
resultset, so partial runs accumulate rather than overwrite. No threshold is
enforced on individual runs — only the merged total from `rake coverage`.

## RBS typing

Update the gem's type signatures before every release:

```bash
bundle exec rbs prototype rb lib/**/*.rb > sig/keycloak-client.rbs
```

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/stepwyz/keycloak-client.

## License

Available as open source under the terms of the [MIT License](LICENSE).
