# frozen_string_literal: true

module CloudLayerio
  # Main client for the cloudlayer.io API.
  # Provides conversion methods (URL/HTML/template to PDF/image),
  # data management (jobs, assets, storage, account, templates),
  # and utility methods (wait_for_job, download_job_result).
  #
  # @example Keyword arguments
  #   client = CloudLayerio::Client.new(api_key: "cl_...", api_version: :v2)
  #   result = client.url_to_pdf(url: "https://example.com")
  #
  # @example Block-based configuration
  #   client = CloudLayerio::Client.new do |config|
  #     config.api_key = "cl_..."
  #     config.api_version = :v2
  #     config.timeout = 60
  #   end
  #
  # @example v2 workflow: convert, poll, download
  #   result = client.url_to_pdf(url: "https://example.com", async: true, storage: true)
  #   job = client.wait_for_job(result.job.id)
  #   data = client.download_job_result(job)
  #   File.binwrite("output.pdf", data)
  class Client
    include Api::Conversion
    include Api::DataManagement

    # @return [Configuration] the frozen client configuration
    attr_reader :config

    # Creates a new client.
    #
    # @param api_key [String] your cloudlayer.io API key (required)
    # @param api_version [Symbol, String] :v1 or :v2 (required)
    # @param base_url [String] API base URL (default: "https://api.cloudlayer.io")
    # @param timeout [Numeric] request timeout in seconds (default: 30)
    # @param max_retries [Integer] retry attempts for 429/5xx (default: 2, max: 5)
    # @param user_agent [String] custom User-Agent header
    # @param headers [Hash] additional HTTP headers
    # @yield [config] optional block for configuration
    # @yieldparam config [Configuration] mutable configuration object
    # @raise [ConfigError] if configuration is invalid
    def initialize(**kwargs)
      @config = Configuration.new
      apply_kwargs(kwargs)
      yield @config if block_given?
      @config.validate!
      @config.freeze
      @transport = Http::Transport.new(@config)
    end

    protected

    attr_reader :transport

    private

    def apply_kwargs(kwargs)
      kwargs.each do |key, value|
        @config.public_send(:"#{key}=", value) if value
      end
    end
  end
end
