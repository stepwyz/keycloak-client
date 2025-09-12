module KeycloakClient
  module Resources
    module Realms
      def realms
        for_realm(nil) { get('/realms') }
      end

      def realm(realm_name)
        for_realm(nil) { get("/realms/#{realm_name}") }
      end

      def create_realm(realm)
        for_realm(nil) { post('/realms', realm) }
      end

      def delete_realm(realm_name)
        for_realm(nil) { delete("/realms/#{realm_name}") }
      end

      def update_realm(realm_name, realm)
        for_realm(nil) { put("/realms/#{realm_name}", realm) }
      end

      def get_client_session_stats(realm_name)
        for_realm(nil) { get("/realms/#{realm_name}/client-session-stats") }
      end
    end
  end
end
