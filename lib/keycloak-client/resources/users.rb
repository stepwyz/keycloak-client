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
        post('/users', user.to_json)
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

      def get_user_sessions(user_id)
        get("/users/#{user_id}/sessions")
      end
    end
  end
end
