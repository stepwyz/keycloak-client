# frozen_string_literal: true

require 'faraday'

module KeycloakClient
  class AdminClient
    include Resources::Users
    include Resources::Realms
    include Resources::Clients
    include Resources::Organizations
    include Resources::Roles
    include Resources::Groups
    include Resources::ClientScopes

    def initialize(realm: nil, username: nil, password: nil)
      @realm = realm || KeycloakClient.config.default_realm
      @realm_stack = [ @realm ]
      @username = username
      @password = password
      @conn = Faraday.new(url: KeycloakClient.config.host) do |faraday|
        faraday.request :authorization, 'Bearer', -> { @token }
        faraday.response :raise_error
        faraday.request :json
        faraday.response :symbolize_json
        faraday.adapter Faraday.default_adapter
      end
    end

    def authorize!
      response = @conn.post("/realms/#{@realm_stack.first}/protocol/openid-connect/token") do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'

        if username.present? && password.present?
          req.body = URI.encode_www_form({
            grant_type: 'password',
            client_id: 'admin-cli',
            username: username,
            password: password
          })
        else
          req.body = URI.encode_www_form({
            grant_type: 'client_credentials',
            client_id: KeycloakClient.config.default_client_id,
            client_secret: KeycloakClient.config.default_client_secret
          })
        end
      end

      @token = response.body[:access_token]
      @token_expires_at = response.body[:expires_in].seconds.from_now
    end

    def for_realm(realm, &block)
      @realm_stack.push(realm)
      yield
    ensure
      @realm_stack.pop
    end

    def authorize_if_needed
      authorize! if token.nil? || token_expires_at.nil? || token_expires_at < 30.seconds.from_now
    end

    def get(path, params = {}, headers = {}, admin_scoped: true)
      authorize_if_needed
      path = "/realms/#{current_realm}#{path}" if current_realm
      path = "/admin#{path}" if admin_scoped
      @conn.get(path, params, headers).body
    end

    def put(path, body = {}, headers = {}, admin_scoped: true)
      authorize_if_needed
      path = "/realms/#{current_realm}#{path}" if current_realm
      path = "/admin#{path}" if admin_scoped
      @conn.put(path, body, headers).body
    end

    def post(path, body = {}, headers = {}, admin_scoped: true)
      authorize_if_needed
      path = "/realms/#{current_realm}#{path}" if current_realm
      path = "/admin#{path}" if admin_scoped
      @conn.post(path, body, headers).body
    end

    def delete(path, params = {}, headers = {}, admin_scoped: true)
      authorize_if_needed
      path = "/realms/#{current_realm}#{path}" if current_realm
      path = "/admin#{path}" if admin_scoped
      @conn.delete(path, params, headers).body
    end

    def form_post(path, body = {}, headers = {}, admin_scoped: true)
      authorize_if_needed
      path = "/realms/#{current_realm}#{path}" if current_realm
      path = "/admin#{path}" if admin_scoped
      @conn.post(path, body, headers) do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = URI.encode_www_form(body)
      end.body
    end

    def current_realm
      @realm_stack.last
    end

  private

    attr_reader :token, :token_expires_at, :username, :password
  end
end
