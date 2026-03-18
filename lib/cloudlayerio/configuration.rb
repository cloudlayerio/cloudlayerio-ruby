# frozen_string_literal: true

module CloudLayerio
  # Mutable configuration object used during Client initialization.
  # Validated and frozen after the configuration block completes.
  class Configuration
    # @return [String] your cloudlayer.io API key
    # @return [Symbol, String] API version (:v1 or :v2)
    # @return [String] API base URL (default: "https://api.cloudlayer.io")
    # @return [Numeric] request timeout in seconds (default: 30)
    # @return [Integer] retry attempts for 429/5xx on data endpoints (default: 2, max: 5)
    # @return [String] custom User-Agent header string
    # @return [Hash] additional HTTP headers sent with every request
    attr_accessor :api_key, :api_version, :base_url, :timeout,
                  :max_retries, :user_agent, :headers

    DEFAULT_BASE_URL = 'https://api.cloudlayer.io'
    DEFAULT_TIMEOUT = 30
    DEFAULT_MAX_RETRIES = 2
    MAX_RETRIES_LIMIT = 5

    def initialize
      @base_url = DEFAULT_BASE_URL
      @timeout = DEFAULT_TIMEOUT
      @max_retries = DEFAULT_MAX_RETRIES
      @user_agent = "cloudlayerio-ruby/#{VERSION}"
      @headers = {}
    end

    # Validates all configuration values. Called before freeze.
    def validate!
      validate_api_key
      validate_api_version
      validate_base_url
      validate_timeout
      validate_max_retries
    end

    # Returns the resolved api_version string ("v1" or "v2").
    def resolved_api_version
      case @api_version
      when :v1, 'v1' then 'v1'
      when :v2, 'v2' then 'v2'
      else @api_version.to_s
      end
    end

    private

    def validate_api_key
      return unless @api_key.nil? || @api_key.to_s.strip.empty?

      raise ConfigError, 'api_key is required and must be a non-empty string'
    end

    def validate_api_version
      valid = %i[v1 v2] + %w[v1 v2]
      return if valid.include?(@api_version)

      raise ConfigError,
            'api_version must be :v1, :v2, "v1", or "v2" ' \
            "(got #{@api_version.inspect})"
    end

    def validate_base_url
      uri = URI.parse(@base_url.to_s)
      return if uri.is_a?(URI::HTTP)

      raise ConfigError, "base_url must be a valid HTTP(S) URL (got #{@base_url.inspect})"
    rescue URI::InvalidURIError
      raise ConfigError, "base_url is not a valid URL (got #{@base_url.inspect})"
    end

    def validate_timeout
      return if @timeout.is_a?(Numeric) && @timeout.positive?

      raise ConfigError, "timeout must be a positive number (got #{@timeout.inspect})"
    end

    def validate_max_retries
      @max_retries = @max_retries.to_i.clamp(0, MAX_RETRIES_LIMIT)
    end
  end
end
