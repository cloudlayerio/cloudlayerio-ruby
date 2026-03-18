# frozen_string_literal: true

module CloudLayerio
  module Responses
    # Result from a conversion API call, wrapping either a Job (v2) or binary data (v1).
    class ConversionResult
      # @return [Job, String] Job object (v2) or raw binary string (v1)
      # @return [ResponseHeaders] parsed cl-* response headers
      # @return [Integer] HTTP status code
      # @return [String, nil] suggested output filename from Content-Disposition header
      attr_reader :data, :headers, :status, :filename

      def initialize(data:, headers:, status:, filename: nil)
        @data = data
        @headers = headers
        @status = status
        @filename = filename
      end

      # Returns the Job when the result is a v2 async/job response.
      #
      # @return [Job, nil]
      def job
        @data if job?
      end

      # Returns the binary data when the result is a v1 binary response.
      #
      # @return [String, nil]
      def bytes
        @data if binary?
      end

      # Whether the result contains a Job (v2 response).
      def job?
        @data.is_a?(Job)
      end

      # Whether the result contains binary data (v1 response).
      def binary?
        @data.is_a?(String)
      end
    end
  end
end
