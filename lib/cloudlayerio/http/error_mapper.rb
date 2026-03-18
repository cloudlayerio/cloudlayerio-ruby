# frozen_string_literal: true

module CloudLayerio
  module Http
    # Maps HTTP responses and exceptions to CloudLayerio error classes.
    module ErrorMapper
      FILENAME_PATTERN = /filename="?([^";\s]+)"?/

      module_function

      def map_response_error(response, req)
        status = response.code.to_i
        body = response.body || ''
        message = extract_error_message(body, status, response.message)

        error_opts = {
          status_code: status, status_text: response.message,
          path: req.path, method_name: req.method, response_body: body
        }

        case status
        when 401, 403
          raise AuthError.new(message, **error_opts)
        when 429
          raise RateLimitError.new(message, retry_after: parse_retry_after(response), **error_opts)
        else
          raise ApiError.new(message, **error_opts)
        end
      end

      def map_network_error(error)
        case error
        when Net::OpenTimeout, Net::ReadTimeout
          raise TimeoutError, "Request timed out: #{error.message}"
        else
          raise NetworkError, "Connection failed: #{error.message}"
        end
      end

      def extract_error_message(body, status, status_text)
        parsed = JSON.parse(body)
        parsed['message'] || parsed['error'] || "API error: #{status} #{status_text}"
      rescue JSON::ParserError
        "API error: #{status} #{status_text}"
      end

      def parse_retry_after(response)
        value = response['Retry-After']
        return nil unless value

        Integer(value)
      rescue ArgumentError
        nil
      end

      def parse_filename(response)
        disposition = response['Content-Disposition']
        return nil unless disposition

        match = FILENAME_PATTERN.match(disposition)
        match&.[](1)
      end
    end
  end
end
