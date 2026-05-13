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
end
