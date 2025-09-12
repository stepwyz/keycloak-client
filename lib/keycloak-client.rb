# frozen_string_literal: true

require 'active_support/all'

require_relative 'keycloak-client/version'
require_relative 'keycloak-client/configuration'
require_relative 'keycloak-client/railtie' if defined?(Rails)

require_relative 'middleware/faraday/symbolize_json'

Faraday::Response.register_middleware(symbolize_json: Middleware::Faraday::SymbolizeJson)

module KeycloakClient
  autoload :AdminClient, 'keycloak-client/admin_client'
  autoload :Resources, 'keycloak-client/resources'

  class << self
    attr_writer :config

    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
    end

    def root
      @root ||= Pathname.new(__dir__).parent
    end
  end
end
