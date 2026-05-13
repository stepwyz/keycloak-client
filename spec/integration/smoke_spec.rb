# frozen_string_literal: true

RSpec.describe 'live Keycloak smoke', :integration do
  let(:admin) { AdminClientBuilder.build }

  it 'authorizes' do
    expect { admin.authorize! }.to_not raise_error
  end

  it 'lists at least the test realm' do
    names = admin.realms.map { |r| r[:realm] }
    expect(names).to include(ENV.fetch('KEYCLOAK_TEST_REALM'))
  end

  it 'reports auth mode' do
    expect(ENV.fetch('KC_AUTH', 'password')).to match(/\A(password|service)\z/)
  end
end
