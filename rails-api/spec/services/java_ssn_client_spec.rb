# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JavaSsnClient do
  let(:java_service_url) { 'http://java-service:8080' }
  let(:valid_ssn) { '234-56-7890' }
  let(:invalid_ssn) { '000-00-0000' }

  before do
    # Reset any cached configuration
    JavaSsnClient.reset_configuration!

    # Mock environment variables
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('JAVA_SERVICE_URL').and_return(java_service_url)
    allow(ENV).to receive(:fetch).with('JAVA_SERVICE_TIMEOUT', anything).and_return('5')
    allow(ENV).to receive(:fetch).with('JAVA_SERVICE_MAX_RETRIES', anything).and_return('3')
    allow(ENV).to receive(:fetch).with('JAVA_SERVICE_RETRY_DELAY', anything).and_return('0.5')
  end

  describe '.process' do
    context 'with a valid SSN' do
      let(:successful_response) do
        {
          'valid' => true,
          'errors' => [],
          'encryptedSsn' => 'KS8QXdm3xOZX3bap5dxBpT+IpSJFgK9T8GStnvnq9/YKVeyWoXqS',
          'lastFour' => '7890'
        }
      end

      before do
        stub_request(:post, "#{java_service_url}/api/ssn/process")
          .with(
            body: { ssn: valid_ssn }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(
            status: 200,
            body: successful_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns successful response with snake_case keys' do
        result = JavaSsnClient.process(valid_ssn)

        expect(result['valid']).to be true
        expect(result['errors']).to be_empty
        expect(result['encrypted_ssn']).to eq('KS8QXdm3xOZX3bap5dxBpT+IpSJFgK9T8GStnvnq9/YKVeyWoXqS')
        expect(result['last_four']).to eq('7890')
      end

      it 'sends POST request to /api/ssn/process endpoint' do
        JavaSsnClient.process(valid_ssn)

        expect(WebMock).to have_requested(:post, "#{java_service_url}/api/ssn/process")
          .with(
            body: { ssn: valid_ssn }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          .once
      end
    end

    context 'with an invalid SSN' do
      let(:error_response) do
        {
          'valid' => false,
          'errors' => [
            'Area number cannot be 000.',
            'Group number cannot be 00.',
            'Serial number cannot be 0000.'
          ],
          'encryptedSsn' => nil,
          'lastFour' => nil
        }
      end

      before do
        stub_request(:post, "#{java_service_url}/api/ssn/process")
          .with(
            body: { ssn: invalid_ssn }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(
            status: 200,
            body: error_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns validation errors with snake_case keys' do
        result = JavaSsnClient.process(invalid_ssn)

        expect(result['valid']).to be false
        expect(result['errors']).to include('Area number cannot be 000.')
        expect(result['errors']).to include('Group number cannot be 00.')
        expect(result['errors']).to include('Serial number cannot be 0000.')
        expect(result['encrypted_ssn']).to be_nil
        expect(result['last_four']).to be_nil
      end
    end

    context 'when Java service is unavailable' do
      before do
        stub_request(:post, "#{java_service_url}/api/ssn/process")
          .to_raise(Errno::ECONNREFUSED)
      end

      it 'raises a connection error after retries' do
        expect { JavaSsnClient.process(valid_ssn) }
          .to raise_error(JavaSsnClient::ConnectionError, /Failed to connect to Java SSN service after 4 attempts/)
      end

      it 'retries the configured number of times' do
        expect { JavaSsnClient.process(valid_ssn) }.to raise_error(JavaSsnClient::ConnectionError)

        # Initial attempt + 3 retries = 4 total attempts
        expect(WebMock).to have_requested(:post, "#{java_service_url}/api/ssn/process").times(4)
      end
    end

    context 'when Java service times out' do
      before do
        stub_request(:post, "#{java_service_url}/api/ssn/process")
          .to_timeout
      end

      it 'raises a timeout error after retries' do
        expect { JavaSsnClient.process(valid_ssn) }
          .to raise_error(JavaSsnClient::TimeoutError, /Java SSN service request timed out after 4 attempts/)
      end
    end

    context 'when Java service returns 400 client error' do
      before do
        stub_request(:post, "#{java_service_url}/api/ssn/process")
          .to_return(status: 400, body: 'Bad Request')
      end

      it 'raises a client error without retrying' do
        expect { JavaSsnClient.process(valid_ssn) }
          .to raise_error(JavaSsnClient::ClientError, /Invalid request: 400/)

        # Should NOT retry on 4xx errors
        expect(WebMock).to have_requested(:post, "#{java_service_url}/api/ssn/process").once
      end
    end

    context 'when Java service returns 500 server error' do
      before do
        stub_request(:post, "#{java_service_url}/api/ssn/process")
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises a service error after retries' do
        expect { JavaSsnClient.process(valid_ssn) }
          .to raise_error(JavaSsnClient::ServiceError, /Java SSN service returned error: 500/)

        # Should retry on 5xx errors
        expect(WebMock).to have_requested(:post, "#{java_service_url}/api/ssn/process").times(4)
      end
    end

    context 'when Java service returns invalid JSON' do
      before do
        stub_request(:post, "#{java_service_url}/api/ssn/process")
          .to_return(status: 200, body: 'not json')
      end

      it 'raises a parsing error' do
        expect { JavaSsnClient.process(valid_ssn) }
          .to raise_error(JavaSsnClient::ParseError, /Failed to parse Java SSN service response/)
      end
    end

    context 'with retry logic on transient failures' do
      before do
        # First two attempts fail, third succeeds
        stub_request(:post, "#{java_service_url}/api/ssn/process")
          .to_raise(Errno::ECONNREFUSED).then
          .to_timeout.then
          .to_return(
            status: 200,
            body: {
              'valid' => true,
              'errors' => [],
              'encryptedSsn' => 'encrypted',
              'lastFour' => '7890'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'retries failed requests and eventually succeeds' do
        result = JavaSsnClient.process(valid_ssn)

        expect(result['valid']).to be true
        expect(result['encrypted_ssn']).to eq('encrypted')
        expect(WebMock).to have_requested(:post, "#{java_service_url}/api/ssn/process").times(3)
      end
    end
  end

  describe '.validate' do
    let(:validation_response) do
      {
        'valid' => true,
        'errors' => []
      }
    end

    before do
      stub_request(:post, "#{java_service_url}/api/ssn/validate")
        .with(
          body: { ssn: valid_ssn }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(
          status: 200,
          body: validation_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'calls the validate endpoint and returns snake_case keys' do
      result = JavaSsnClient.validate(valid_ssn)

      expect(result['valid']).to be true
      expect(result['errors']).to be_empty
    end

    it 'sends POST request to /api/ssn/validate endpoint' do
      JavaSsnClient.validate(valid_ssn)

      expect(WebMock).to have_requested(:post, "#{java_service_url}/api/ssn/validate")
        .with(
          body: { ssn: valid_ssn }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        .once
    end
  end

  describe '.decrypt' do
    let(:encrypted_ssn) { 'KS8QXdm3xOZX3bap5dxBpT+IpSJFgK9T8GStnvnq9/YKVeyWoXqS' }
    let(:decrypt_response) do
      {
        'ssn' => '234-56-7890'
      }
    end

    before do
      stub_request(:post, "#{java_service_url}/api/ssn/decrypt")
        .with(
          body: { encryptedSsn: encrypted_ssn }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(
          status: 200,
          body: decrypt_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'calls the decrypt endpoint' do
      result = JavaSsnClient.decrypt(encrypted_ssn)

      expect(result['ssn']).to eq('234-56-7890')
    end
  end

  describe 'configuration' do
    context 'when JAVA_SERVICE_URL is not set' do
      before do
        JavaSsnClient.reset_configuration!
        allow(ENV).to receive(:fetch).with('JAVA_SERVICE_URL').and_raise(KeyError)
      end

      it 'raises a ConfigurationError' do
        expect { JavaSsnClient.process(valid_ssn) }
          .to raise_error(JavaSsnClient::ConfigurationError, /JAVA_SERVICE_URL environment variable is required/)
      end
    end

    context 'with custom configuration' do
      before do
        JavaSsnClient.reset_configuration!
        allow(ENV).to receive(:fetch).with('JAVA_SERVICE_URL').and_return('http://custom:9000')
        allow(ENV).to receive(:fetch).with('JAVA_SERVICE_TIMEOUT', anything).and_return('10')
        allow(ENV).to receive(:fetch).with('JAVA_SERVICE_MAX_RETRIES', anything).and_return('5')
        allow(ENV).to receive(:fetch).with('JAVA_SERVICE_RETRY_DELAY', anything).and_return('1.0')
      end

      it 'uses custom configuration values' do
        # Access private methods for testing
        expect(JavaSsnClient.send(:timeout)).to eq(10)
        expect(JavaSsnClient.send(:max_retries)).to eq(5)
        expect(JavaSsnClient.send(:retry_delay)).to eq(1.0)
      end
    end
  end
end