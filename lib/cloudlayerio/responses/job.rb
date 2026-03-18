# frozen_string_literal: true

module CloudLayerio
  module Responses
    # Represents a CloudLayer.io job returned by the API.
    class Job
      FIELDS = %i[
        id uid name type status timestamp
        worker_name process_time api_key_used
        process_time_cost api_credit_cost bandwidth_cost total_cost
        size params asset_url preview_url self_url asset_id project_id error
      ].freeze

      # JSON key -> Ruby attr mapping for non-standard keys
      JSON_TO_ATTR = {
        'self' => :self_url,
        'workerName' => :worker_name,
        'processTime' => :process_time,
        'apiKeyUsed' => :api_key_used,
        'processTimeCost' => :process_time_cost,
        'apiCreditCost' => :api_credit_cost,
        'bandwidthCost' => :bandwidth_cost,
        'totalCost' => :total_cost,
        'assetUrl' => :asset_url,
        'previewUrl' => :preview_url,
        'assetId' => :asset_id,
        'projectId' => :project_id
      }.freeze

      attr_reader(*FIELDS)

      def initialize(**kwargs)
        FIELDS.each do |f|
          instance_variable_set(:"@#{f}", kwargs[f])
        end
      end

      # Parses a Job from a camelCase JSON hash (string keys).
      #
      # @param hash [Hash] parsed JSON with string keys
      # @return [Job]
      def self.from_hash(hash)
        attrs = {}
        hash.each do |key, value|
          attr = JSON_TO_ATTR[key] || Util::JsonSerializer.camel_to_snake(key).to_sym
          attrs[attr] = value if FIELDS.include?(attr)
        end
        new(**attrs)
      end

      # Returns the timestamp as milliseconds, handling both numeric ms
      # and Firestore _seconds/_nanoseconds format defensively.
      #
      # @return [Integer, nil]
      def timestamp_ms
        return nil if @timestamp.nil?

        if @timestamp.is_a?(Hash)
          seconds = @timestamp['_seconds'] || @timestamp[:_seconds]
          nanos = @timestamp['_nanoseconds'] || @timestamp[:_nanoseconds]
          return nil unless seconds

          (seconds.to_i * 1000) + (nanos.to_i / 1_000_000)
        else
          @timestamp.to_i
        end
      end

      def success?
        @status == JobStatus::SUCCESS
      end

      def pending?
        @status == JobStatus::PENDING
      end

      def error?
        @status == JobStatus::ERROR
      end
    end
  end
end
