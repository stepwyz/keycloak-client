# frozen_string_literal: true

# Must be loaded before the gem itself so SimpleCov sees every line.
require_relative 'support/coverage'

require "debug/prelude"
require "dotenv"
Dotenv.load('.env.local', '.env')

require "keycloak-client"

KeycloakClient.root.glob('spec/support/**/*.rb').sort.each { |f| require f }

KeycloakClient.configure do |config|
  config.host = ENV.fetch('KEYCLOAK_HOST', 'http://localhost:8080')
  config.realm = ENV.fetch('KEYCLOAK_REALM', 'master')
  config.client_id = ENV.fetch('KEYCLOAK_CLIENT_ID', 'admin-cli')
  config.client_secret = ENV.fetch('KEYCLOAK_CLIENT_SECRET', '')
end

RSpec.configure do |config|
  config.include ExpectationsHelper

  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run_when_matching :focus

  # Unit specs only by default. Integration specs require a live Keycloak —
  # set KC_LIVE=1 (or run `rake integration`) to include them. The bootstrap
  # provisions a fresh test realm before the suite runs.
  if ENV['KC_LIVE'] == '1'
    config.before(:suite) { KeycloakBootstrap.run! }
  else
    config.filter_run_excluding :integration
  end
end
