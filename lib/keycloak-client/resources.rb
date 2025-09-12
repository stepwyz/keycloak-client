module KeycloakClient
  module Resources
    autoload :Users, 'keycloak-client/resources/users'
    autoload :Realms, 'keycloak-client/resources/realms'
    autoload :Clients, 'keycloak-client/resources/clients'
    autoload :Organizations, 'keycloak-client/resources/organizations'
    autoload :Roles, 'keycloak-client/resources/roles'
    autoload :Groups, 'keycloak-client/resources/groups'
    autoload :ClientScopes, 'keycloak-client/resources/client_scopes'
  end
end
