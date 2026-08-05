# frozen_string_literal: true

RSpec.describe KeycloakClient::AdminClient do
  context 'with an established client' do
    let(:client) { described_class.new(username: 'admin', password: 'admin') } # Defined by docker-compose.yml

    describe '#authorize!' do
      subject { client.authorize! }

      it { is_anticipated.to_not raise_error }

      context 'with invalid credentials' do
        let(:client) { described_class.new(username: 'admin', password: 'invalid') }

        # Keycloak answers a bad direct-grant password with 400 invalid_grant,
        # reserving 401 for failures to authenticate the client itself.
        it { is_anticipated.to raise_error(Faraday::BadRequestError) }
      end
    end
  end
end
