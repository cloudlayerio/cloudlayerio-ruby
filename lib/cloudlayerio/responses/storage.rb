# frozen_string_literal: true

module CloudLayerio
  module Responses
    # A storage configuration summary from list endpoints.
    class StorageListItem
      # @return [String] storage configuration ID
      # @return [String] human-readable title
      attr_reader :id, :title

      def initialize(id:, title:)
        @id = id
        @title = title
      end

      def self.from_hash(hash)
        new(
          id: hash['id'],
          title: hash['title']
        )
      end
    end

    # Full storage configuration detail.
    class StorageDetail
      # @return [String] storage configuration ID
      # @return [String] human-readable title
      attr_reader :id, :title

      def initialize(id:, title:)
        @id = id
        @title = title
      end

      def self.from_hash(hash)
        new(
          id: hash['id'],
          title: hash['title']
        )
      end
    end

    # Response from creating a storage configuration.
    class StorageCreateResponse
      # @return [String] new storage configuration ID
      # @return [String] human-readable title
      attr_reader :id, :title

      def initialize(id:, title:)
        @id = id
        @title = title
      end

      def self.from_hash(hash)
        new(
          id: hash['id'],
          title: hash['title']
        )
      end
    end

    # HTTP 200 response when storage is not allowed on the user's plan.
    class StorageNotAllowedResponse
      # @return [Boolean] false when storage is not available
      # @return [String] human-readable reason message
      # @return [Integer] original HTTP status code from the response body
      attr_reader :allowed, :reason, :status_code

      def initialize(allowed:, reason:, status_code:)
        @allowed = allowed
        @reason = reason
        @status_code = status_code
      end

      def self.from_hash(hash)
        new(
          allowed: hash['allowed'],
          reason: hash['reason'],
          status_code: hash['statusCode']
        )
      end
    end
  end
end
