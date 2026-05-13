# frozen_string_literal: true

RSpec.describe 'live: ClientScopes resource', :integration do
  let(:admin) { AdminClientBuilder.build }

  it 'creates a client scope and attaches it to a client as default/optional' do
    scope_name = "scope-#{SecureRandom.hex(4)}"
    admin.create_client_scope(name: scope_name, protocol: 'openid-connect')
    scope = admin.client_scopes.detect { |s| s[:name] == scope_name }
    expect(scope).not_to be_nil

    client_id_str = "csclient-#{SecureRandom.hex(4)}"
    admin.create_client(clientId: client_id_str, protocol: 'openid-connect', publicClient: true)
    client = admin.clients.detect { |c| c[:clientId] == client_id_str }

    expect { admin.add_default_client_scope(client[:id], scope[:id]) }.to_not raise_error
    expect { admin.remove_default_client_scope(client[:id], scope[:id]) }.to_not raise_error

    expect { admin.add_optional_client_scope(client[:id], scope[:id]) }.to_not raise_error
    expect { admin.remove_optional_client_scope(client[:id], scope[:id]) }.to_not raise_error
  ensure
    admin.delete_client(client[:id]) if client
  end
end
