# frozen_string_literal: true

# Builds an AdminClient for the integration suite based on KC_AUTH.
#
# Both auth modes are scoped to the throwaway test realm:
#   - password: test-admin user (created by KeycloakBootstrap)
#   - service:  integration-suite service-account client
#
# Cross-realm operations (the Realms resource) need master-realm credentials —
# use AdminClientBuilder.master_admin for those specs.
module AdminClientBuilder
  module_function

  def build
    realm = ENV.fetch('KEYCLOAK_TEST_REALM')
    case ENV.fetch('KC_AUTH', 'password')
    when 'password'
      KeycloakClient::AdminClient.new(
        realm: realm,
        username: ENV.fetch('KEYCLOAK_TEST_USERNAME'),
        password: ENV.fetch('KEYCLOAK_TEST_PASSWORD')
      )
    when 'service'
      KeycloakClient.config.realm         = realm
      KeycloakClient.config.client_id     = ENV.fetch('KEYCLOAK_TEST_CLIENT_ID')
      KeycloakClient.config.client_secret = ENV.fetch('KEYCLOAK_TEST_CLIENT_SECRET')
      KeycloakClient::AdminClient.new
    else
      raise "Unknown KC_AUTH=#{ENV['KC_AUTH'].inspect} (expected 'password' or 'service')"
    end
  end

  def master_admin
    KeycloakClient::AdminClient.new(realm: 'master', username: 'admin', password: 'admin')
  end
end
