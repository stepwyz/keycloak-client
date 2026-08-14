module KeycloakClient
  class Configuration
    DEFAULT_TIMEOUT = 10
    DEFAULT_OPEN_TIMEOUT = 2
    DEFAULT_MAIL_TIMEOUT = 30

    attr_accessor :host, :client_id, :client_secret, :realm, :timeout, :open_timeout, :mail_timeout

    def initialize
      @host = ENV['KEYCLOAK_HOST']
      @client_id = ENV['KEYCLOAK_CLIENT_ID']
      @client_secret = ENV['KEYCLOAK_CLIENT_SECRET']
      @realm = ENV['KEYCLOAK_REALM']
      @timeout = DEFAULT_TIMEOUT
      @open_timeout = DEFAULT_OPEN_TIMEOUT
      @mail_timeout = DEFAULT_MAIL_TIMEOUT
    end
  end
end
