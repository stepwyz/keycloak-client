module KeycloakClient
  module Resources
    module Roles
      def realm_roles
        get('/roles')
      end

      def get_realm_role(name)
        get("/roles/#{name}")
      end

      def create_realm_role(role_representation)
        post('/roles', role_representation)
      end

      def update_realm_role(name, role_representation)
        put("/roles/#{name}", role_representation)
      end

      def delete_realm_role(name)
        delete("/roles/#{name}")
      end

      def client_roles(client_id)
        get("/clients/#{client_id}/roles")
      end

      def user_roles(user_id)
        get("/users/#{user_id}/role-mappings")
      end

      def assign_client_role(role, client_id:, user_id:)
        post("/users/#{user_id}/role-mappings/clients/#{client_id}", Array.wrap(role).to_json)
      end

      def get_realm_role_composites(name)
        get("/roles/#{name}/composites")
      end

      def add_realm_role_composites(name, roles)
        post("/roles/#{name}/composites", roles)
      end

      def delete_realm_role_composites(name, roles)
        delete("/roles/#{name}/composites", roles)
      end

      def get_realm_role_realm_composites(name)
        get("/roles/#{name}/composites/realm")
      end

      def get_realm_role_client_composites(name, client_id)
        get("/roles/#{name}/composites/clients/#{client_id}")
      end
    end
  end
end
