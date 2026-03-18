# frozen_string_literal: true

module CloudLayerio
  module Responses
    # API status/health check response.
    class StatusResponse
      # @return [String] API status string (e.g. "ok ")
      attr_reader :status

      def initialize(status:)
        @status = status
      end

      def self.from_hash(hash)
        new(status: hash['status'])
      end
    end
  end
end
