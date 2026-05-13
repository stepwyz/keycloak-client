# frozen_string_literal: true

# Realms-management endpoints are cross-realm, so they need master-realm
# credentials, not the in-realm test-admin / service-account. This spec uses
# its own master/admin client and is tagged :master_admin so the service-auth
# rake task can exclude it (no master-realm service account exists by default).
RSpec.describe 'live: Realms resource', :integration, :master_admin do
  let(:admin) { AdminClientBuilder.master_admin }

  it 'lists realms including master and the test realm' do
    names = admin.realms.map { |r| r[:realm] }
    expect(names).to include('master', ENV.fetch('KEYCLOAK_TEST_REALM'))
  end

  it 'reads, updates, and deletes a throwaway realm' do
    name = "throwaway-#{SecureRandom.hex(4)}"
    admin.create_realm(realm: name, enabled: true)

    expect(admin.realm(name)[:realm]).to eq(name)

    admin.update_realm(name, realm: name, enabled: false)
    expect(admin.realm(name)[:enabled]).to eq(false)

    expect { admin.delete_realm(name) }.to_not raise_error
  end

  it 'returns client session stats for the test realm' do
    stats = admin.get_client_session_stats(ENV.fetch('KEYCLOAK_TEST_REALM'))
    expect(stats).to be_an(Array)
  end
end
