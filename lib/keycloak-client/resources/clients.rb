module KeycloakClient
  module Resources
    module Clients
      def clients
        get('/clients')
      end

      def client(client_uuid)
        get("/clients/#{client_uuid}")
      end

      def create_client(client)
        post('/clients', client)
      end

      def delete_client(client_uuid)
        delete("/clients/#{client_uuid}")
      end

      def update_client(client_uuid, client)
        put("/clients/#{client_uuid}", client)
      end

      def get_client_secret(client_uuid)
        get("/clients/#{client_uuid}/client-secret")
      end

      def generate_client_secret(client_uuid)
        post("/clients/#{client_uuid}/client-secret")
      end

      def get_installation_provider(client_uuid, provider_id)
        get("/clients/#{client_uuid}/installation/providers/#{provider_id}")
      end

      def get_service_account_user(client_uuid)
        get("/clients/#{client_uuid}/service-account-user")
      end

      def push_client_revocation_policy(client_uuid)
        post("/clients/#{client_uuid}/push-revocation")
      end

      def test_client_clusters_availability(client_uuid)
        get("/clients/#{client_uuid}/test-nodes-available")
      end

      def get_client_sessions(client_uuid)
        get("/clients/#{client_uuid}/user-sessions")
      end

      def get_client_offline_sessions(client_uuid)
        get("/clients/#{client_uuid}/offline-sessions")
      end

      def register_client_cluster_node(client_uuid)
        post("/clients/#{client_uuid}/nodes")
      end

      def unregister_client_cluster_node(client_uuid, node)
        delete("/clients/#{client_uuid}/nodes/#{node}")
      end

      def get_client_session_count(client_uuid)
        get("/clients/#{client_uuid}/session-count")
      end
    end
  end
end
