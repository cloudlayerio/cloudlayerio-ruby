# frozen_string_literal: true

module CloudLayerio
  # Base error class for all CloudLayerio SDK errors.
  class Error < StandardError; end

  # Raised when client configuration is invalid (bad API key, URL, timeout, etc.).
  class ConfigError < Error; end

  # Raised for client-side input validation failures
  # (empty URL, empty HTML, batch >20, mutually exclusive options, etc.).
  class ValidationError < Error; end

  # Raised on connection/DNS failures. Wraps the original socket-level error
  # which is accessible via Ruby's built-in Exception#cause.
  class NetworkError < Error; end

  # Raised when an SDK-level timeout is exceeded (distinct from HTTP 408).
  # Wraps Net::ReadTimeout / Net::OpenTimeout via Exception#cause.
  class TimeoutError < Error; end

  # Raised on HTTP 4xx/5xx responses from the API.
  class ApiError < Error
    # @return [Integer, nil] HTTP status code (e.g. 400, 404, 500)
    # @return [String, nil] HTTP status text (e.g. "Bad Request")
    # @return [String, nil] request path (e.g. "/url/pdf")
    # @return [String, nil] HTTP method (e.g. "POST")
    # @return [String, nil] raw response body
    attr_reader :status_code, :status_text, :path, :method_name, :response_body

    def initialize(message = nil, **kwargs)
      @status_code = kwargs[:status_code]
      @status_text = kwargs[:status_text]
      @path = kwargs[:path]
      @method_name = kwargs[:method_name]
      @response_body = kwargs[:response_body]
      super(message || build_message)
    end

    private

    def build_message
      parts = []
      parts << "HTTP #{@status_code}" if @status_code
      parts << @status_text if @status_text
      parts << "#{@method_name} #{@path}" if @path
      parts.empty? ? 'API error' : parts.join(' - ')
    end
  end

  # Raised on HTTP 401 or 403 responses (authentication/authorization failure).
  class AuthError < ApiError; end

  # Raised on HTTP 429 responses (rate limit exceeded).
  # Includes retry_after parsed from the Retry-After header when available.
  class RateLimitError < ApiError
    # @return [Integer, nil] seconds to wait before retrying (from Retry-After header)
    attr_reader :retry_after

    def initialize(message = nil, retry_after: nil, **kwargs)
      @retry_after = retry_after
      super(message, **kwargs)
    end
  end
end
