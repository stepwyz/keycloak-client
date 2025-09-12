module KeycloakClient
  class Configuration
    attr_accessor :host, :client_id, :client_secret, :default_realm, :default_client_id, :default_client_secret

    def initialize
      @host = ENV['KEYCLOAK_HOST']
      @client_id = ENV['KEYCLOAK_CLIENT_ID']
      @client_secret = ENV['KEYCLOAK_CLIENT_SECRET']
      @default_realm = ENV['KEYCLOAK_DEFAULT_REALM']
      @default_client_id = ENV['KEYCLOAK_DEFAULT_CLIENT_ID']
      @default_client_secret = ENV['KEYCLOAK_DEFAULT_CLIENT_SECRET']
    end
  end
end
