module KeycloakClient
  class Configuration
    attr_accessor :host, :client_id, :client_secret, :realm

    def initialize
      @host = ENV['KEYCLOAK_HOST']
      @client_id = ENV['KEYCLOAK_CLIENT_ID']
      @client_secret = ENV['KEYCLOAK_CLIENT_SECRET']
      @realm = ENV['KEYCLOAK_REALM']
    end
  end
end
