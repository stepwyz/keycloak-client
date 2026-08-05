# frozen_string_literal: true

RSpec.describe 'live: Organizations resource', :integration do
  let(:admin) { AdminClientBuilder.build }

  let(:org_alias) { "org-#{SecureRandom.hex(4)}" }

  before do
    admin.create_organization(
      name: org_alias,
      alias: org_alias,
      domains: [{ name: "#{org_alias}.example.com", verified: true }]
    )
  end

  let!(:org) { admin.organization_by_alias(org_alias) }

  after { admin.delete_organization(org[:id]) if org && admin.organization(org[:id]) rescue nil }

  it 'creates, reads, updates, and lists organizations' do
    expect(org[:alias]).to eq(org_alias)

    admin.update_organization(org[:id], org.merge(description: 'renamed'))
    expect(admin.organization(org[:id])[:description]).to eq('renamed')

    expect(admin.organizations.map { |o| o[:alias] }).to include(org_alias)
  end

  it 'manages organization members' do
    username = "orguser-#{SecureRandom.hex(4)}"
    admin.create_user(username: username, enabled: true, email: "#{username}@example.com")
    user = admin.users(username: username, exact: true).first

    admin.create_organization_membership(org[:id], user[:id].to_json)

    expect(admin.get_organization_member_count(org[:id])).to eq(1)
    expect(admin.get_organization_members(org[:id]).map { |m| m[:id] }).to include(user[:id])
    expect(admin.get_organization_member(org[:id], user[:id])[:id]).to eq(user[:id])

    admin.remove_user(org[:id], user[:id])
    expect(admin.get_organization_member_count(org[:id])).to eq(0)
  ensure
    admin.delete_user(user[:id]) if user
  end

  it 'invites an existing user' do
    skip 'set KEYCLOAK_SMTP_PASSWORD to run' unless ENV['KEYCLOAK_SMTP_PASSWORD']

    username = "inv-#{SecureRandom.hex(4)}"
    admin.create_user(username: username, enabled: true, email: "#{username}@example.com")
    user = admin.users(username: username, exact: true).first

    expect { admin.invite_existing_user(org[:id], user[:id]) }.to_not raise_error
  ensure
    admin.delete_user(user[:id]) if user
  end

  it 'invites an address with no account yet' do
    skip 'set KEYCLOAK_SMTP_PASSWORD to run' unless ENV['KEYCLOAK_SMTP_PASSWORD']

    expect { admin.invite_user(org[:id], "invitee-#{SecureRandom.hex(4)}@example.com") }
      .to_not raise_error
  end

  it "lists the organizations a user belongs to" do
    username = "mem-#{SecureRandom.hex(4)}"
    admin.create_user(username: username, enabled: true, email: "#{username}@example.com")
    user = admin.users(username: username, exact: true).first
    admin.create_organization_membership(org[:id], user[:id].to_json)

    result = admin.get_user_organizations(user[:id])
    expect(result).to be_an(Array)
    expect(result.map { |o| o[:alias] }).to include(org_alias)

    scoped = admin.get_organization_member_organizations(org[:id], user[:id])
    expect(scoped.map { |o| o[:alias] }).to include(org_alias)
  ensure
    admin.delete_user(user[:id]) if user
  end

  describe 'organization identity providers' do
    let!(:idp_alias) { "idp-#{SecureRandom.hex(4)}" }

    before do
      # Identity providers must exist at the realm level before linking to an org.
      admin.post('/identity-provider/instances', {
        alias: idp_alias,
        providerId: 'oidc',
        enabled: true,
        config: {
          clientId: 'placeholder',
          clientSecret: 'placeholder',
          authorizationUrl: 'https://example.com/oauth/authorize',
          tokenUrl: 'https://example.com/oauth/token'
        }
      })
    end

    after { admin.delete("/identity-provider/instances/#{idp_alias}") rescue nil }

    it 'links, lists, reads, and unlinks an identity provider' do
      expect(admin.organization_identity_providers(org[:id])).to eq([])

      admin.add_organization_identity_provider(org[:id], idp_alias)

      linked = admin.organization_identity_providers(org[:id])
      expect(linked.map { |i| i[:alias] }).to include(idp_alias)

      fetched = admin.organization_identity_provider(org[:id], idp_alias)
      expect(fetched[:alias]).to eq(idp_alias)

      expect { admin.remove_organization_identity_provider(org[:id], idp_alias) }.to_not raise_error
      expect(admin.organization_identity_providers(org[:id])).to eq([])
    end
  end
end
