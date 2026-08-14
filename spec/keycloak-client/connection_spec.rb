# frozen_string_literal: true

RSpec.describe KeycloakClient::AdminClient do
  let(:default_timeout) { KeycloakClient::Configuration::DEFAULT_TIMEOUT }
  let(:default_open_timeout) { KeycloakClient::Configuration::DEFAULT_OPEN_TIMEOUT }
  let(:mail_timeout) { KeycloakClient::Configuration::DEFAULT_MAIL_TIMEOUT }

  describe '#initialize' do
    subject(:request_options) { client.instance_variable_get(:@conn).options }

    let(:client) { described_class.new }

    it { is_expected.to have_attributes(timeout: default_timeout, open_timeout: default_open_timeout) }

    context 'when the caller overrides the timeouts' do
      let(:client) { described_class.new(timeout: 20, open_timeout: 5) }

      it { is_expected.to have_attributes(timeout: 20, open_timeout: 5) }
    end

    it 'leaves the process-wide Faraday defaults alone' do
      will

      expect(Faraday.default_connection_options.request.timeout).to be_nil
    end
  end

  context 'when the connection is stubbed' do
    let(:client) { described_class.new }
    let(:conn) { client.instance_variable_get(:@conn) }
    let(:request) { conn.build_request(:put) }

    before do
      allow(client).to receive(:authorize_if_needed)
      allow(conn).to receive(:put) do |*_args, &block|
        block&.call(request)
        instance_double(Faraday::Response, body: nil)
      end
    end

    describe '#send_verify_email' do
      subject { client.send_verify_email('user-id') }

      it { will; expect(request.options.timeout).to eq(mail_timeout) }

      context 'when the client timeout already exceeds the mail timeout' do
        let(:client) { described_class.new(timeout: 45) }

        it { will; expect(request.options.timeout).to eq(45) }
      end
    end

    describe '#send_reset_password_email' do
      subject { client.send_reset_password_email('user-id') }

      it { will; expect(request.options.timeout).to eq(mail_timeout) }
    end

    describe '#execute_actions_email' do
      subject { client.execute_actions_email('user-id', [ 'UPDATE_PASSWORD' ]) }

      it { will; expect(request.options.timeout).to eq(mail_timeout) }
    end

    describe '#put' do
      subject { client.put('/users/user-id') }

      it { will; expect(request.options.timeout).to eq(default_timeout) }
    end
  end
end
