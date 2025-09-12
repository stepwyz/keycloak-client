# frozen_string_literal: true

require "debug/prelude"
require "keycloak-client"

KeycloakClient.root.glob('spec/support/**/*.rb').sort.each { |f| require f }

KeycloakClient.configure do |config|
  config.host = 'http://localhost:8080'
  config.realm = 'master' # Need to create a new realm for testing
  config.client_id = 'admin_cli' # Need to create a new client for testing
  config.client_secret = 'admin' # Need to create a new client for testing
end

RSpec.configure do |config|
  config.include ExpectationsHelper

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
