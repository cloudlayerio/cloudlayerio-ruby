# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module CloudLayerio
  module Http
    # HTTP transport layer handling all communication with the CloudLayer.io API.
    class Transport
      REDIRECT_LIMIT = 5
      NETWORK_ERRORS = [
        SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET,
        Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError
      ].freeze

      def initialize(config)
        @config = config
        @retry_policy = RetryPolicy.new(config.max_retries)
      end

      # POST with JSON body.
      def post_json(path, body_hash, retryable: false)
        url = build_url(path)
        json_body = JSON.generate(body_hash)

        execute(retryable: retryable) do
          uri = URI.parse(url)
          req = Net::HTTP::Post.new(uri)
          apply_headers(req)
          req['Content-Type'] = 'application/json'
          req.body = json_body
          perform_request(uri, req)
        end
      end

      # POST with multipart form-data body.
      def post_multipart(path, parts, retryable: false)
        url = build_url(path)
        body, content_type = Multipart.build(parts)

        execute(retryable: retryable) do
          uri = URI.parse(url)
          req = Net::HTTP::Post.new(uri)
          apply_headers(req)
          req['Content-Type'] = content_type
          req.body = body
          perform_request(uri, req)
        end
      end

      # GET with optional query parameters.
      def get(path, query_params: {}, retryable: true, absolute_path: false)
        url = build_url(path, absolute_path: absolute_path)

        execute(retryable: retryable) do
          uri = URI.parse(url)
          uri.query = URI.encode_www_form(query_params) unless query_params.empty?
          req = Net::HTTP::Get.new(uri)
          apply_headers(req)
          perform_request(uri, req)
        end
      end

      # DELETE request.
      def delete(path, retryable: false)
        url = build_url(path)

        execute(retryable: retryable) do
          uri = URI.parse(url)
          req = Net::HTTP::Delete.new(uri)
          apply_headers(req)
          perform_request(uri, req)
        end
      end

      # GET returning raw binary data. No X-API-Key. Follows redirects.
      def get_raw(url)
        fetch_raw(url, REDIRECT_LIMIT)
      end

      private

      def build_url(path, absolute_path: false)
        if absolute_path
          "#{@config.base_url}#{path}"
        else
          "#{@config.base_url}/#{@config.resolved_api_version}#{path}"
        end
      end

      def apply_headers(req)
        req['X-API-Key'] = @config.api_key
        req['User-Agent'] = @config.user_agent
        @config.headers.each { |k, v| req[k] = v }
      end

      def execute(retryable: false)
        if retryable
          @retry_policy.execute { |_attempt| yield }
        else
          yield
        end
      end

      def perform_request(uri, req)
        response = send_http(uri, req)
        handle_response(response, req)
      rescue Net::OpenTimeout, Net::ReadTimeout, *NETWORK_ERRORS => e
        ErrorMapper.map_network_error(e)
      end

      def send_http(uri, req)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.open_timeout = @config.timeout
        http.read_timeout = @config.timeout
        http.request(req)
      end

      def handle_response(response, req)
        status = response.code.to_i
        content_type = response['Content-Type'] || ''

        return ErrorMapper.map_response_error(response, req) if status >= 400

        if json_response?(content_type)
          parse_json_response(response)
        else
          parse_binary_response(response)
        end
      end

      def json_response?(content_type)
        content_type.include?('application/json') || content_type.include?('text/json')
      end

      def parse_json_response(response)
        body = JSON.parse(response.body || '{}')
        headers = Responses::ResponseHeaders.from_http_headers(response)
        { data: body, headers: headers, status: response.code.to_i }
      end

      def parse_binary_response(response)
        headers = Responses::ResponseHeaders.from_http_headers(response)
        {
          data: response.body,
          headers: headers,
          status: response.code.to_i,
          filename: ErrorMapper.parse_filename(response)
        }
      end

      def fetch_raw(url, redirects_remaining)
        raise NetworkError, "Too many redirects (limit: #{REDIRECT_LIMIT})" if redirects_remaining <= 0

        uri = URI.parse(url)
        req = Net::HTTP::Get.new(uri)
        req['User-Agent'] = @config.user_agent

        response = send_http(uri, req)
        handle_raw_response(response, url, redirects_remaining)
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        raise TimeoutError, "Download timed out: #{e.message}"
      rescue *NETWORK_ERRORS => e
        raise NetworkError, "Download connection failed: #{e.message}"
      end

      def handle_raw_response(response, url, redirects_remaining)
        case response
        when Net::HTTPRedirection
          location = response['Location']
          raise NetworkError, 'Redirect without Location header' unless location

          fetch_raw(location, redirects_remaining - 1)
        when Net::HTTPSuccess
          { body: response.body, headers: response, status: response.code.to_i }
        else
          raise ApiError.new(
            "Download failed: #{response.code} #{response.message}",
            status_code: response.code.to_i, status_text: response.message,
            path: url, method_name: 'GET', response_body: response.body
          )
        end
      end
    end
  end
end
