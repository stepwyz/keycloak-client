# frozen_string_literal: true

require 'faraday'

# Provisions a clean test realm + service account + admin user against the
# live Keycloak running on KEYCLOAK_HOST (or http://localhost:8080).
#
# Idempotent: drops and recreates the test realm every run.
#
# Exports values back to ENV so two RSpec invocations (one per auth mode) can
# pick up the same realm/secret:
#
#   KEYCLOAK_TEST_REALM      — realm everything lives in
#   KEYCLOAK_TEST_USERNAME   — admin user inside that realm
#   KEYCLOAK_TEST_PASSWORD   — its password
#   KEYCLOAK_TEST_CLIENT_ID  — service-account client_id
#   KEYCLOAK_TEST_CLIENT_SECRET — its secret
module KeycloakBootstrap
  TEST_REALM         = 'keycloak-client-test'
  TEST_ADMIN_USER    = 'test-admin'
  TEST_ADMIN_PASS    = 'test-admin-password'
  SERVICE_CLIENT_ID  = 'integration-suite'
  SERVICE_CLIENT_SEC = 'integration-suite-secret'

  module_function

  def run!
    wait_for_keycloak!

    admin = KeycloakClient::AdminClient.new(
      realm: 'master', username: 'admin', password: 'admin'
    )

    drop_realm(admin, TEST_REALM)
    create_realm(admin, TEST_REALM)

    admin.for_realm(TEST_REALM) do
      provision_service_account(admin)
      provision_admin_user(admin)
    end

    publish_env
  end

  def publish_env
    ENV['KEYCLOAK_TEST_REALM']          = TEST_REALM
    ENV['KEYCLOAK_TEST_USERNAME']       = TEST_ADMIN_USER
    ENV['KEYCLOAK_TEST_PASSWORD']       = TEST_ADMIN_PASS
    ENV['KEYCLOAK_TEST_CLIENT_ID']      = SERVICE_CLIENT_ID
    ENV['KEYCLOAK_TEST_CLIENT_SECRET']  = SERVICE_CLIENT_SEC
  end

  def wait_for_keycloak!
    url = "#{KeycloakClient.config.host}/realms/master/protocol/openid-connect/certs"
    print 'Waiting for Keycloak to be ready'
    50.times do |i|
      status = `curl -s -o /dev/null -w '%{http_code}' #{url}`.to_i
      return puts "\nKeycloak is ready!" if status == 200
      # Keycloak's master realm defaults to sslRequired=external, which
      # blocks plain-HTTP requests coming over docker-desktop's NAT bridge.
      # Flip it to NONE via kcadm.sh inside the container — only needed once.
      disable_master_ssl_requirement! if status == 403 && i.zero?
      print '.'
      sleep 1
    end
    raise "Keycloak never became ready at #{url}"
  end

  def disable_master_ssl_requirement!
    container = ENV.fetch('KEYCLOAK_CONTAINER', 'keycloak_web')
    kcadm = "/opt/keycloak/bin/kcadm.sh"
    system(
      "docker exec #{container} #{kcadm} config credentials " \
      "--server http://localhost:8080 --realm master --user admin --password admin > /dev/null 2>&1"
    ) || return
    system("docker exec #{container} #{kcadm} update realms/master -s 'sslRequired=NONE' > /dev/null 2>&1")
  end

  def drop_realm(admin, name)
    admin.delete_realm(name)
  rescue Faraday::ResourceNotFound
    # already gone
  end

  def create_realm(admin, name)
    body = {
      realm: name,
      enabled: true,
      sslRequired: 'NONE', # allow plain-HTTP from docker-bridge IPs
      loginWithEmailAllowed: true,
      duplicateEmailsAllowed: false,
      registrationAllowed: false,
      organizationsEnabled: true
    }

    if ENV['KEYCLOAK_SMTP_PASSWORD']
      body[:smtpServer] = {
        password: ENV['KEYCLOAK_SMTP_PASSWORD'],
        host: ENV.fetch('KEYCLOAK_SMTP_HOST', 'smtp-relay.gmail.com'),
        port: ENV.fetch('KEYCLOAK_SMTP_PORT', '587'),
        user: ENV.fetch('KEYCLOAK_SMTP_USER', 'dan@stepwyz.com'),
        from: ENV.fetch('KEYCLOAK_SMTP_FROM', 'hello@stepwyz.com'),
        fromDisplayName: 'keycloak-client integration tests',
        auth: true,
        starttls: true,
        ssl: false
      }
    end

    admin.create_realm(body)
  end

  def provision_service_account(admin)
    admin.create_client(
      clientId: SERVICE_CLIENT_ID,
      secret: SERVICE_CLIENT_SEC,
      protocol: 'openid-connect',
      publicClient: false,
      bearerOnly: false,
      standardFlowEnabled: false,
      directAccessGrantsEnabled: false,
      serviceAccountsEnabled: true,
      clientAuthenticatorType: 'client-secret'
    )

    service_client = find_client(admin, SERVICE_CLIENT_ID)
    sa_user = admin.get_service_account_user(service_client[:id])

    realm_mgmt = find_client(admin, 'realm-management')
    realm_admin_role = admin
      .client_roles(realm_mgmt[:id])
      .detect { |r| r[:name] == 'realm-admin' }

    admin.assign_client_role(
      realm_admin_role,
      client_id: realm_mgmt[:id],
      user_id: sa_user[:id]
    )
  end

  def provision_admin_user(admin)
    admin.create_user(
      username: TEST_ADMIN_USER,
      enabled: true,
      emailVerified: true,
      email: "#{TEST_ADMIN_USER}@example.com",
      firstName: 'Test',
      lastName: 'Admin',
      credentials: [
        { type: 'password', value: TEST_ADMIN_PASS, temporary: false }
      ]
    )

    user = admin.users(username: TEST_ADMIN_USER, exact: true).first

    realm_mgmt = find_client(admin, 'realm-management')
    realm_admin_role = admin
      .client_roles(realm_mgmt[:id])
      .detect { |r| r[:name] == 'realm-admin' }

    admin.assign_client_role(
      realm_admin_role,
      client_id: realm_mgmt[:id],
      user_id: user[:id]
    )
  end

  def find_client(admin, client_id)
    # Resources::Clients#clients takes no params, so go through the raw client.
    admin.get('/clients', { clientId: client_id }).first
  end
end
