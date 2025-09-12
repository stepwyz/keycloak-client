module KeycloakClient
  module Resources
    module Roles
      # Get realm-level roles
      def realm_roles
        get('/roles')
      end

      # Get a specific realm-level role by name
      def get(name)
        get("/roles/#{name}")
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

      # Create a new realm-level role
      def create(role_representation)
        post('/roles', role_representation)
      end

      # Update a realm-level role by name
      def update(name, role_representation)
        put("/roles/#{name}", role_representation)
      end

      # Delete a realm-level role by name
      def delete(name)
        delete("/roles/#{name}")
      end

      # Get composite roles for a realm-level role
      def get_composites(name)
        get("/roles/#{name}/composites")
      end

      # Add composite roles to a realm-level role
      def add_composites(name, roles)
        post("/roles/#{name}/composites", roles)
      end

      # Remove composite roles from a realm-level role
      def delete_composites(name, roles)
        delete("/roles/#{name}/composites", roles)
      end

      # Get realm-level roles in a role's composite
      def get_realm_composites(name)
        get("/roles/#{name}/composites/realm")
      end

      # Get client-level roles for a client in a role's composite
      def get_client_composites(name, client_id)
        get("/roles/#{name}/composites/clients/#{client_id}")
      end
    end
  end
end
