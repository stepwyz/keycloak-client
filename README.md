# Keycloak::Client

TODO: Delete this and the text below, and describe your gem

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/keycloak/client`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Live integration testing

The repo ships with an integration suite (`spec/integration/*_spec.rb`) that
exercises the client against a real Keycloak server. Specs are tagged
`:integration` and only run when `KC_LIVE=1` is set; the `rake integration`
task does this for you.

Bring up a disposable Keycloak via the bundled `docker-compose.yml`:

```bash
KEYCLOAK_HOST_PORT=8082 docker compose up -d
```

The `KEYCLOAK_HOST_PORT` env var picks the host port (defaults to `8080`).
The container exposes Keycloak on `http://localhost:8082`, admin
credentials `admin` / `admin`.

Run the integration suite against it:

```bash
KEYCLOAK_HOST=http://localhost:8082 bundle exec rake integration
```

The task runs the suite twice — once under each auth mode supported by
`AdminClient#authorize!`:

- `integration:password` — admin username/password against an in-realm
  admin user
- `integration:service` — service account via `client_credentials` against
  a confidential client

A `before(:suite)` hook in `spec_helper.rb` runs
`spec/support/keycloak_bootstrap.rb`, which drops and recreates a
throwaway realm (`keycloak-client-test`) on every run and provisions:

- `test-admin` / `test-admin-password` — realm-admin user used by the
  password mode
- `integration-suite` confidential client (secret
  `integration-suite-secret`) with `realm-admin` granted to its service
  account, used by the service mode

Cross-realm tests in `spec/integration/realms_spec.rb` are tagged
`:master_admin` and use the master-realm `admin/admin` user; the
`integration:service` task skips them automatically.

The relevant env vars (all optional in non-live mode) are:

| Variable | Default |
|---|---|
| `KEYCLOAK_HOST` | `http://localhost:8080` |
| `KEYCLOAK_REALM` | `master` |
| `KEYCLOAK_CLIENT_ID` | `admin-cli` |
| `KEYCLOAK_CLIENT_SECRET` | `` |
| `KEYCLOAK_HOST_PORT` (compose only) | `8080` |
| `KEYCLOAK_SMTP_PASSWORD` (integration only) | unset — when set, the bootstrap configures the test realm's SMTP server so specs that send email (e.g. `Organizations#invite_existing_user`) can succeed instead of skipping. `KEYCLOAK_SMTP_HOST/PORT/USER/FROM` further override defaults (`smtp-relay.gmail.com:587`, `dan@stepwyz.com`, `hello@stepwyz.com`). |

## RBS Typing
Update the type signatures of the gem by running the following. This should be run before every release of a new version.
`bundle exec rbs prototype rb lib/**/*.rb > sig/keycloak-client.rbs`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/keycloak-client.
