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

  it 'updates a realm role' do
    name = "role-#{SecureRandom.hex(4)}"
    admin.create_realm_role(name: name, description: 'before')

    admin.update_realm_role(name, admin.get_realm_role(name).merge(description: 'after'))
    expect(admin.get_realm_role(name)[:description]).to eq('after')
  ensure
    admin.delete_realm_role(name) rescue nil
  end

  describe 'composites' do
    let!(:parent) { "role-#{SecureRandom.hex(4)}" }
    let!(:child) { "role-#{SecureRandom.hex(4)}" }

    before do
      admin.create_realm_role(name: parent)
      admin.create_realm_role(name: child)
    end

    after do
      admin.delete_realm_role(parent) rescue nil
      admin.delete_realm_role(child) rescue nil
    end

    it 'adds, lists, and removes a realm composite' do
      child_role = admin.get_realm_role(child)

      admin.add_realm_role_composites(parent, [child_role])
      expect(admin.get_realm_role_composites(parent).map { |r| r[:name] }).to eq([child])
      expect(admin.get_realm_role_realm_composites(parent).map { |r| r[:name] }).to eq([child])

      admin.delete_realm_role_composites(parent, [child_role])
      expect(admin.get_realm_role_composites(parent)).to eq([])
    end

    it 'lists client composites for a role that has none' do
      realm_mgmt = admin.get('/clients', { clientId: 'realm-management' }).first
      expect(admin.get_realm_role_client_composites(parent, realm_mgmt[:id])).to eq([])
    end
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
