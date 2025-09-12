module KeycloakClient
  module Resources
    module ClientScopes
      def client_scopes(params = {})
        get('/client-scopes', params)
      end

      def create_client_scope(scope)
        post('/client-scopes', scope)
      end

      def add_default_client_scope(client_id, scope_id)
        put("/clients/#{client_id}/default-client-scopes/#{scope_id}")
      end

      def remove_default_client_scope(client_id, scope_id)
        delete("/clients/#{client_id}/default-client-scopes/#{scope_id}")
      end

      def add_optional_client_scope(client_id, scope_id)
        put("/clients/#{client_id}/optional-client-scopes/#{scope_id}")
      end

      def remove_optional_client_scope(client_id, scope_id)
        delete("/clients/#{client_id}/optional-client-scopes/#{scope_id}")
      end
    end
  end
end
