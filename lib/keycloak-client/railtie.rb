module KeycloakClient
  class Railtie < Rails::Railtie
    initializer 'keycloak-client.configure' do
      # KeycloakClient.configure do |config|
      #   config.host = ENV.fetch('KEYCLOAK_HOST')
      # end
    end
  end
end
