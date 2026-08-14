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

    def initialize(realm: nil, username: nil, password: nil, timeout: nil, open_timeout: nil)
      @realm = realm || KeycloakClient.config.realm
      @realm_stack = [ @realm ]
      @username = username
      @password = password
      @timeout = timeout || KeycloakClient.config.timeout
      request_options = {
        timeout: @timeout,
        open_timeout: open_timeout || KeycloakClient.config.open_timeout
      }
      @conn = Faraday.new(url: KeycloakClient.config.host, request: request_options) do |faraday|
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
            client_id: 'admin-cli', # TODO: Should be configurable
            username: username,
            password: password
          })
        else
          req.body = URI.encode_www_form({
            grant_type: 'client_credentials',
            client_id: KeycloakClient.config.client_id,
            client_secret: KeycloakClient.config.client_secret
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

    def put(path, body = {}, headers = {}, params: nil, timeout: nil, admin_scoped: true)
      authorize_if_needed
      path = "/realms/#{current_realm}#{path}" if current_realm
      path = "/admin#{path}" if admin_scoped
      path = "#{path}?#{URI.encode_www_form(params.compact)}" if params&.compact&.any?
      @conn.put(path, body, headers) { |req| req.options.timeout = timeout if timeout }.body
    end

    def post(path, body = {}, headers = {}, params: nil, admin_scoped: true)
      authorize_if_needed
      path = "/realms/#{current_realm}#{path}" if current_realm
      path = "/admin#{path}" if admin_scoped
      path = "#{path}?#{URI.encode_www_form(params.compact)}" if params&.compact&.any?
      @conn.post(path, body, headers).body
    end

    def create(path, body = {}, headers = {}, params: nil, admin_scoped: true)
      authorize_if_needed
      path = "/realms/#{current_realm}#{path}" if current_realm
      path = "/admin#{path}" if admin_scoped
      path = "#{path}?#{URI.encode_www_form(params.compact)}" if params&.compact&.any?
      @conn.post(path, body, headers).headers['location'].to_s.split('/').last.presence
    end

    # A handful of admin endpoints (role composites, for one) take a JSON body
    # on DELETE, which Faraday only sends when the request is built by block.
    def delete(path, params = {}, headers = {}, body: nil, admin_scoped: true)
      authorize_if_needed
      path = "/realms/#{current_realm}#{path}" if current_realm
      path = "/admin#{path}" if admin_scoped
      @conn.delete(path, params, headers) { |req| req.body = body unless body.nil? }.body
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

    def mail_timeout
      [ @timeout, KeycloakClient.config.mail_timeout ].max
    end

    attr_reader :token, :token_expires_at, :username, :password
  end
end
