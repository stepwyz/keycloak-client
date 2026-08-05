# frozen_string_literal: true

RSpec.describe 'live: Clients resource', :integration do
  let(:admin) { AdminClientBuilder.build }

  it 'creates, reads, updates, and deletes a client' do
    client_id_str = "client-#{SecureRandom.hex(4)}"
    admin.create_client(
      clientId: client_id_str,
      protocol: 'openid-connect',
      publicClient: false,
      standardFlowEnabled: false,
      directAccessGrantsEnabled: false,
      clientAuthenticatorType: 'client-secret'
    )

    fetched = admin.clients.detect { |c| c[:clientId] == client_id_str }
    expect(fetched).not_to be_nil

    secret = admin.get_client_secret(fetched[:id])
    expect(secret[:value]).to be_a(String)

    admin.update_client(fetched[:id], fetched.merge(description: 'updated'))
    expect(admin.client(fetched[:id])[:description]).to eq('updated')

    expect { admin.delete_client(fetched[:id]) }.to_not raise_error
  end

  context 'with a confidential service-account client' do
    let!(:client) do
      client_id_str = "client-#{SecureRandom.hex(4)}"
      admin.create_client(
        clientId: client_id_str,
        protocol: 'openid-connect',
        publicClient: false,
        serviceAccountsEnabled: true,
        standardFlowEnabled: false,
        clientAuthenticatorType: 'client-secret'
      )
      admin.clients.detect { |c| c[:clientId] == client_id_str }
    end

    after { admin.delete_client(client[:id]) rescue nil }

    it 'rotates the client secret' do
      original = admin.get_client_secret(client[:id])[:value]

      rotated = admin.generate_client_secret(client[:id])
      expect(rotated[:type]).to eq('secret')
      expect(rotated[:value]).not_to eq(original)
      expect(admin.get_client_secret(client[:id])[:value]).to eq(rotated[:value])
    end

    it 'renders the adapter installation config' do
      config = admin.get_installation_provider(client[:id], 'keycloak-oidc-keycloak-json')

      # This endpoint answers with text, not JSON, so it comes back unparsed.
      expect(config).to include(ENV.fetch('KEYCLOAK_TEST_REALM'))
      expect(config).to include(client[:clientId])
    end

    it 'resolves the service account user' do
      expect(admin.get_service_account_user(client[:id])[:username])
        .to eq("service-account-#{client[:clientId]}")
    end

    describe 'sessions' do
      it 'reports no sessions for a client nobody has logged into' do
        expect(admin.get_client_sessions(client[:id])).to eq([])
        expect(admin.get_client_offline_sessions(client[:id])).to eq([])
        expect(admin.get_client_session_count(client[:id])[:count]).to eq(0)
      end
    end

    describe 'cluster nodes' do
      it 'registers and unregisters a node' do
        admin.register_client_cluster_node(client[:id], 'node1.example.com')
        expect(admin.client(client[:id])[:registeredNodes]).to have_key(:'node1.example.com')

        admin.unregister_client_cluster_node(client[:id], 'node1.example.com')
        expect(admin.client(client[:id])[:registeredNodes]).to be_nil
      end

      it 'unregistering an unknown node 404s — endpoint is correct' do
        expect { admin.unregister_client_cluster_node(client[:id], 'nope.example.com') }
          .to raise_error(Faraday::ResourceNotFound)
      end

      it 'tests cluster availability for a client with no nodes' do
        expect(admin.test_client_clusters_availability(client[:id])).to eq({})
      end
    end

    it 'pushes the revocation policy' do
      expect(admin.push_client_revocation_policy(client[:id])).to eq({})
    end
  end
end
