# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

# Client for communicating with the Java SSN validation and encryption service
class JavaSsnClient
  # Default Java service URL with fallback
  JAVA_SERVICE_URL = ENV.fetch('JAVA_SERVICE_URL', 'http://java-service:8080')

  # Custom error classes for different failure scenarios
  class ConnectionError < StandardError; end
  class TimeoutError < StandardError; end
  class ClientError < StandardError; end
  class ServiceError < StandardError; end
  class ParseError < StandardError; end
  class ConfigurationError < StandardError; end

  class << self
    # Process SSN: validate and encrypt in one operation
    #
    # @param ssn [String] The SSN to process
    # @return [Hash] Response with snake_case keys:
    #   - valid [Boolean] Whether the SSN is valid
    #   - errors [Array<String>] Validation errors (empty if valid)
    #   - encrypted_ssn [String, nil] Encrypted SSN (only if valid)
    #   - last_four [String, nil] Last 4 digits (only if valid)
    # @raise [ConnectionError] If unable to connect to Java service
    # @raise [TimeoutError] If request times out
    # @raise [ClientError] If request is invalid (4xx)
    # @raise [ServiceError] If Java service returns server error (5xx)
    # @raise [ParseError] If response cannot be parsed
    def process(ssn)
      post_with_retry('/api/ssn/process', { ssn: ssn })
    end

    # Validate SSN without encryption
    #
    # @param ssn [String] The SSN to validate
    # @return [Hash] Response with snake_case keys:
    #   - valid [Boolean] Whether the SSN is valid
    #   - errors [Array<String>] Validation errors (empty if valid)
    # @raise [ConnectionError] If unable to connect to Java service
    # @raise [TimeoutError] If request times out
    # @raise [ClientError] If request is invalid (4xx)
    # @raise [ServiceError] If Java service returns server error (5xx)
    # @raise [ParseError] If response cannot be parsed
    def validate(ssn)
      post_with_retry('/api/ssn/validate', { ssn: ssn })
    end

    # Decrypt an encrypted SSN
    #
    # @param encrypted_ssn [String] The encrypted SSN to decrypt
    # @return [Hash] Response with decrypted SSN
    # @raise [ConnectionError] If unable to connect to Java service
    # @raise [TimeoutError] If request times out
    # @raise [ClientError] If request is invalid (4xx)
    # @raise [ServiceError] If Java service returns server error (5xx)
    # @raise [ParseError] If response cannot be parsed
    def decrypt(encrypted_ssn)
      post_with_retry('/api/ssn/decrypt', { encryptedSsn: encrypted_ssn })
    end

    # Allow resetting configuration (useful for testing)
    def reset_configuration!
      @base_url = nil
      @timeout = nil
      @max_retries = nil
      @retry_delay = nil
    end

    private

    # Perform POST request with retry logic and exponential backoff
    #
    # @param path [String] API endpoint path
    # @param body [Hash] Request body to be JSON encoded
    # @param attempt [Integer] Current attempt number (0-indexed)
    # @return [Hash] Parsed response with snake_case keys
    def post_with_retry(path, body, attempt = 0)
      response = make_http_request(path, body)

      # Don't retry on 4xx client errors - these won't succeed on retry
      if response.is_a?(Net::HTTPClientError)
        raise ClientError, "Invalid request: #{response.code} - #{response.body}"
      end

      # Raise error on 5xx server errors
      unless response.is_a?(Net::HTTPSuccess)
        raise ServiceError, "Java SSN service returned error: #{response.code} - #{response.body}"
      end

      # Parse and transform response
      parse_response(response.body)

    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
      retry_or_raise(ConnectionError, "Failed to connect to Java SSN service", e, attempt) do
        post_with_retry(path, body, attempt + 1)
      end

    rescue Net::OpenTimeout, Net::ReadTimeout => e
      retry_or_raise(TimeoutError, "Java SSN service request timed out", e, attempt) do
        post_with_retry(path, body, attempt + 1)
      end

    rescue ServiceError => e
      # Retry on server errors (5xx)
      retry_or_raise(ServiceError, e.message, e, attempt) do
        post_with_retry(path, body, attempt + 1)
      end
    end

    # Make HTTP POST request
    #
    # @param path [String] API endpoint path
    # @param body [Hash] Request body
    # @return [Net::HTTPResponse] HTTP response object
    def make_http_request(path, body)
      uri = URI.parse("#{base_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = timeout
      http.open_timeout = timeout

      request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
      request.body = body.to_json

      http.request(request)
    end

    # Parse JSON response and transform keys to snake_case
    #
    # @param response_body [String] Raw response body
    # @return [Hash] Parsed response with snake_case keys
    def parse_response(response_body)
      parsed = JSON.parse(response_body)
      transform_keys_to_snake_case(parsed)
    rescue JSON::ParserError => e
      raise ParseError, "Failed to parse Java SSN service response: #{e.message}"
    end

    # Transform hash keys from camelCase to snake_case
    #
    # @param hash [Hash] Hash with camelCase keys
    # @return [Hash] Hash with snake_case keys
    def transform_keys_to_snake_case(hash)
      return hash unless hash.is_a?(Hash)

      hash.transform_keys { |key| camel_to_snake(key) }
          .transform_values { |value| value.is_a?(Hash) ? transform_keys_to_snake_case(value) : value }
    end

    # Convert camelCase string to snake_case
    #
    # @param key [String, Symbol] Key to convert
    # @return [String] snake_case version of key
    def camel_to_snake(key)
      key.to_s
         .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
         .gsub(/([a-z\d])([A-Z])/, '\1_\2')
         .downcase
    end

    # Handle retry logic with exponential backoff
    #
    # @param error_class [Class] Error class to raise if max retries exceeded
    # @param message [String] Base error message
    # @param original_error [Exception] Original exception that was caught
    # @param attempt [Integer] Current attempt number (0-indexed)
    # @yield Block to execute for retry
    def retry_or_raise(error_class, message, original_error, attempt)
      if attempt < max_retries
        sleep(retry_delay * (2**attempt)) # Exponential backoff: 0.5s, 1s, 2s, 4s...
        yield
      else
        raise error_class, "#{message} after #{attempt + 1} attempts: #{original_error.message}"
      end
    end

    # Configuration methods with ENV fallbacks

    def base_url
      @base_url ||= JAVA_SERVICE_URL
    end

    def timeout
      @timeout ||= ENV.fetch('JAVA_SERVICE_TIMEOUT', '5').to_i
    end

    def max_retries
      @max_retries ||= ENV.fetch('JAVA_SERVICE_MAX_RETRIES', '3').to_i
    end

    def retry_delay
      @retry_delay ||= ENV.fetch('JAVA_SERVICE_RETRY_DELAY', '0.5').to_f
    end


  end
end