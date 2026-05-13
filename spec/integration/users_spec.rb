# frozen_string_literal: true

RSpec.describe 'live: Users resource', :integration do
  let(:admin) { AdminClientBuilder.build }

  it 'creates, reads, updates, and deletes a user' do
    username = "user-#{SecureRandom.hex(4)}"
    admin.create_user(
      username: username,
      enabled: true,
      email: "#{username}@example.com",
      firstName: 'First',
      lastName: 'Last'
    )

    fetched = admin.users(username: username, exact: true).first
    expect(fetched[:username]).to eq(username)

    admin.update_user(fetched[:id], fetched.merge(firstName: 'Renamed'))
    expect(admin.user(fetched[:id])[:firstName]).to eq('Renamed')

    expect { admin.delete_user(fetched[:id]) }.to_not raise_error
    expect(admin.users(username: username, exact: true)).to be_empty
  end

  it 'returns a numeric user count' do
    expect(admin.user_count).to be_a(Integer)
  end
end
