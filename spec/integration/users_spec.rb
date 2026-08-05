# frozen_string_literal: true

RSpec.describe 'live: Users resource', :integration do
  let(:admin) { AdminClientBuilder.build }

  let!(:user) do
    username = "user-#{SecureRandom.hex(4)}"
    admin.create_user(
      username: username,
      enabled: true,
      email: "#{username}@example.com",
      firstName: 'First',
      lastName: 'Last',
      credentials: [{ type: 'password', value: 'initial-password', temporary: false }]
    )
    admin.users(username: username, exact: true).first
  end

  after { admin.delete_user(user[:id]) rescue nil }

  it 'creates, reads, updates, and deletes a user' do
    expect(user[:username]).to start_with('user-')

    admin.update_user(user[:id], user.merge(firstName: 'Renamed'))
    expect(admin.user(user[:id])[:firstName]).to eq('Renamed')

    expect { admin.delete_user(user[:id]) }.to_not raise_error
    expect(admin.users(username: user[:username], exact: true)).to be_empty
  end

  it 'returns a numeric user count' do
    expect(admin.user_count).to be_a(Integer)
  end

  describe 'sessions and logout' do
    it 'lists user sessions (empty until the user logs in)' do
      expect(admin.get_user_sessions(user[:id])).to eq([])
    end

    it 'logs out a user with no active sessions without error' do
      expect { admin.logout_user(user[:id]) }.to_not raise_error
    end

    it 'lists offline sessions for a client' do
      client = admin.clients.detect { |c| c[:clientId] == 'account' }
      expect(admin.get_user_offline_sessions(user[:id], client[:id])).to eq([])
    end
  end

  describe 'group memberships' do
    it 'lists user groups and counts them' do
      expect(admin.user_groups(user[:id])).to eq([])
      expect(admin.user_group_count(user[:id])[:count]).to eq(0)
    end
  end

  describe 'credentials' do
    let!(:credentials) { admin.user_credentials(user[:id]) }

    it 'lists credentials (the bootstrap password is here)' do
      expect(credentials.map { |c| c[:type] }).to include('password')
    end

    it 'renames a credential' do
      cred = credentials.first
      expect { admin.update_user_credential_label(user[:id], cred[:id], 'pet-name') }.to_not raise_error
      reloaded = admin.user_credentials(user[:id]).detect { |c| c[:id] == cred[:id] }
      expect(reloaded[:userLabel]).to eq('pet-name')
    end

    it 'deletes a credential' do
      cred = credentials.first
      admin.delete_user_credential(user[:id], cred[:id])
      expect(admin.user_credentials(user[:id]).map { |c| c[:id] }).not_to include(cred[:id])
    end

    it 'disables credential types without error' do
      expect { admin.disable_user_credential_types(user[:id], ['otp']) }.to_not raise_error
    end

    it 'lists configured user-storage credential types' do
      expect(admin.configured_user_storage_credential_types(user[:id])).to be_an(Array)
    end

    # Keycloak only ever stores one password, and the admin API has no way to
    # add a second credential, so there is nothing to reorder against. These
    # assert the endpoints accept a well-formed move and leave the credential
    # in place.
    it 'moves a credential to the front of the list' do
      cred = credentials.first
      expect { admin.move_user_credential_to_first(user[:id], cred[:id]) }.to_not raise_error
      expect(admin.user_credentials(user[:id]).map { |c| c[:id] }).to eq([cred[:id]])
    end

    it 'moves a credential after another' do
      cred = credentials.first
      expect { admin.move_user_credential_after(user[:id], cred[:id], cred[:id]) }.to_not raise_error
      expect(admin.user_credentials(user[:id]).map { |c| c[:id] }).to eq([cred[:id]])
    end
  end

  describe 'password reset and action emails' do
    it 'resets the password to a new value' do
      expect do
        admin.reset_user_password(user[:id], type: 'password', value: 'new-password', temporary: false)
      end.to_not raise_error
    end

    it "skips execute_actions_email without SMTP" do
      skip 'set KEYCLOAK_SMTP_PASSWORD to run' unless ENV['KEYCLOAK_SMTP_PASSWORD']
      expect { admin.execute_actions_email(user[:id], %w[UPDATE_PASSWORD]) }.to_not raise_error
    end

    it 'sends a reset-password email' do
      skip 'set KEYCLOAK_SMTP_PASSWORD to run' unless ENV['KEYCLOAK_SMTP_PASSWORD']
      expect { admin.send_reset_password_email(user[:id]) }.to_not raise_error
    end

    it 'sends a verify-email' do
      skip 'set KEYCLOAK_SMTP_PASSWORD to run' unless ENV['KEYCLOAK_SMTP_PASSWORD']
      expect { admin.send_verify_email(user[:id]) }.to_not raise_error
    end
  end

  describe 'consents' do
    it 'lists user consents (empty before any client is consented)' do
      expect(admin.user_consents(user[:id])).to eq([])
    end

    it 'revoking a non-existent consent 404s — endpoint is correct' do
      expect { admin.revoke_user_consent(user[:id], 'account') }.to raise_error(Faraday::ResourceNotFound)
    end
  end

  describe 'federated identity' do
    it 'lists federated identities (empty for a freshly created user)' do
      expect(admin.user_federated_identities(user[:id])).to eq([])
    end

    it 'removing a non-linked provider 404s — endpoint is correct' do
      expect { admin.remove_user_federated_identity(user[:id], 'github') }
        .to raise_error(Faraday::ResourceNotFound)
    end

    context 'with a matching identity provider in the realm' do
      # A link is only listed once the realm has an identity provider under
      # that alias, so the spec has to provision one. There is no IdP resource
      # on the client yet, hence the raw calls.
      before do
        admin.post('/identity-provider/instances',
                   { alias: 'github', providerId: 'github', enabled: true,
                     config: { clientId: 'irrelevant', clientSecret: 'irrelevant' } })
      end

      after { admin.delete('/identity-provider/instances/github') rescue nil }

      it 'links and unlinks a federated identity' do
        admin.add_user_federated_identity(user[:id], 'github', userId: 'gh-1', userName: 'ghuser')
        expect(admin.user_federated_identities(user[:id]))
          .to eq([{ identityProvider: 'github', userId: 'gh-1', userName: 'ghuser' }])

        admin.remove_user_federated_identity(user[:id], 'github')
        expect(admin.user_federated_identities(user[:id])).to eq([])
      end
    end
  end

  describe 'unmanaged attributes' do
    it 'returns the unmanaged attributes map' do
      expect(admin.user_unmanaged_attributes(user[:id])).to eq({})
    end
  end

  describe 'users profile (UPConfig)' do
    it 'reads, updates, and reads metadata for the user-profile config' do
      profile = admin.users_profile
      expect(profile).to be_a(Hash)

      expect { admin.update_users_profile(profile) }.to_not raise_error

      metadata = admin.users_profile_metadata
      expect(metadata[:attributes]).to be_an(Array)
    end
  end

  describe 'impersonation' do
    # Impersonation requires an admin session/cookie; the API responds with a
    # redirect that isn't useful here. We just assert the endpoint exists.
    it 'returns impersonation response without error' do
      result = admin.impersonate_user(user[:id])
      expect(result).to be_a(Hash)
    end
  end
end
