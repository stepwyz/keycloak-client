module KeycloakClient
  module Resources
    module Users
      def user_count
        get('/users/count')
      end

      def users(params = {})
        get('/users', params)
      end

      def user(user_id)
        get("/users/#{user_id}")
      end

      def create_user(user)
        post('/users', user)
      end

      def delete_user(user_id)
        delete("/users/#{user_id}")
      end

      def update_user(user_id, user)
        put("/users/#{user_id}", user)
      end

      def send_reset_password_email(user_id)
        put("/users/#{user_id}/reset-password-email")
      end

      def send_verify_email(user_id)
        put("/users/#{user_id}/send-verify-email")
      end

      def execute_actions_email(user_id, actions, client_id: nil, lifespan: nil, redirect_uri: nil)
        put("/users/#{user_id}/execute-actions-email", actions, {},
            params: { client_id:, lifespan:, redirect_uri: })
      end

      def reset_user_password(user_id, credential)
        put("/users/#{user_id}/reset-password", credential)
      end

      def logout_user(user_id)
        post("/users/#{user_id}/logout")
      end

      def impersonate_user(user_id)
        post("/users/#{user_id}/impersonation")
      end

      def get_user_sessions(user_id)
        get("/users/#{user_id}/sessions")
      end

      def get_user_offline_sessions(user_id, client_uuid)
        get("/users/#{user_id}/offline-sessions/#{client_uuid}")
      end

      def user_groups(user_id, params = {})
        get("/users/#{user_id}/groups", params)
      end

      def user_group_count(user_id)
        get("/users/#{user_id}/groups/count")
      end

      def user_consents(user_id)
        get("/users/#{user_id}/consents")
      end

      def revoke_user_consent(user_id, client_id)
        delete("/users/#{user_id}/consents/#{client_id}")
      end

      def user_credentials(user_id)
        get("/users/#{user_id}/credentials")
      end

      def delete_user_credential(user_id, credential_id)
        delete("/users/#{user_id}/credentials/#{credential_id}")
      end

      def move_user_credential_after(user_id, credential_id, after_credential_id)
        post("/users/#{user_id}/credentials/#{credential_id}/moveAfter/#{after_credential_id}")
      end

      def move_user_credential_to_first(user_id, credential_id)
        post("/users/#{user_id}/credentials/#{credential_id}/moveToFirst")
      end

      def update_user_credential_label(user_id, credential_id, label)
        put("/users/#{user_id}/credentials/#{credential_id}/userLabel", label,
            { 'Content-Type' => 'text/plain' })
      end

      def disable_user_credential_types(user_id, credential_types)
        put("/users/#{user_id}/disable-credential-types", credential_types)
      end

      def configured_user_storage_credential_types(user_id)
        get("/users/#{user_id}/configured-user-storage-credential-types")
      end

      def user_federated_identities(user_id)
        get("/users/#{user_id}/federated-identity")
      end

      def add_user_federated_identity(user_id, provider, federated_identity)
        post("/users/#{user_id}/federated-identity/#{provider}", federated_identity)
      end

      def remove_user_federated_identity(user_id, provider)
        delete("/users/#{user_id}/federated-identity/#{provider}")
      end

      def user_unmanaged_attributes(user_id)
        get("/users/#{user_id}/unmanagedAttributes")
      end

      def users_profile
        get('/users/profile')
      end

      def update_users_profile(profile)
        put('/users/profile', profile)
      end

      def users_profile_metadata
        get('/users/profile/metadata')
      end
    end
  end
end
