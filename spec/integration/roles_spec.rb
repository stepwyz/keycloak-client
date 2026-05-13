# frozen_string_literal: true

RSpec.describe 'live: Roles resource', :integration do
  let(:admin) { AdminClientBuilder.build }

  it 'lists realm roles' do
    expect(admin.realm_roles.map { |r| r[:name] }).to include('default-roles-' + ENV.fetch('KEYCLOAK_TEST_REALM'))
  end

  it 'creates, reads, and deletes a realm role' do
    name = "role-#{SecureRandom.hex(4)}"
    admin.create_realm_role(name: name, description: 'integration test')

    fetched = admin.get_realm_role(name)
    expect(fetched[:name]).to eq(name)

    admin.delete_realm_role(name)
    expect(admin.realm_roles.map { |r| r[:name] }).not_to include(name)
  end

  it 'lists client roles for realm-management' do
    realm_mgmt = admin.get('/clients', { clientId: 'realm-management' }).first
    role_names = admin.client_roles(realm_mgmt[:id]).map { |r| r[:name] }
    expect(role_names).to include('realm-admin')
  end

  it 'assigns a client role to a user' do
    username = "rolee-#{SecureRandom.hex(4)}"
    admin.create_user(username: username, enabled: true)
    user = admin.users(username: username, exact: true).first

    realm_mgmt = admin.get('/clients', { clientId: 'realm-management' }).first
    role = admin.client_roles(realm_mgmt[:id]).detect { |r| r[:name] == 'view-users' }

    admin.assign_client_role(role, client_id: realm_mgmt[:id], user_id: user[:id])

    mapped = admin.user_roles(user[:id])
    expect(mapped[:clientMappings].values.flat_map { |c| c[:mappings].map { |m| m[:name] } })
      .to include('view-users')
  ensure
    admin.delete_user(user[:id]) if user
  end
end
