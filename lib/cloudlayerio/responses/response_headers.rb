# frozen_string_literal: true

module CloudLayerio
  module Responses
    # Parsed cl-* response headers from the CloudLayer.io API.
    class ResponseHeaders
      HEADER_MAP = {
        'cl-worker-job-id' => :worker_job_id,
        'cl-cluster-id' => :cluster_id,
        'cl-worker' => :worker,
        'cl-bandwidth' => :bandwidth,
        'cl-process-time' => :process_time,
        'cl-calls-remaining' => :calls_remaining,
        'cl-charged-time' => :charged_time,
        'cl-bandwidth-cost' => :bandwidth_cost,
        'cl-process-time-cost' => :process_time_cost,
        'cl-api-credit-cost' => :api_credit_cost
      }.freeze

      INTEGER_FIELDS = %i[bandwidth process_time calls_remaining charged_time].freeze
      FLOAT_FIELDS   = %i[bandwidth_cost process_time_cost api_credit_cost].freeze

      # @return [String, nil] cl-worker-job-id header value
      # @return [String, nil] cl-cluster-id header value
      # @return [String, nil] cl-worker header value
      # @return [Integer, nil] cl-bandwidth bytes consumed
      # @return [Integer, nil] cl-process-time processing time in ms
      # @return [Integer, nil] cl-calls-remaining API calls remaining
      # @return [Integer, nil] cl-charged-time charged compute time in ms
      # @return [Float, nil] cl-bandwidth-cost bandwidth cost in credits
      # @return [Float, nil] cl-process-time-cost processing cost in credits
      # @return [Float, nil] cl-api-credit-cost total API credit cost
      attr_reader :worker_job_id, :cluster_id, :worker,
                  :bandwidth, :process_time,
                  :calls_remaining, :charged_time,
                  :bandwidth_cost, :process_time_cost, :api_credit_cost

      def initialize(**kwargs)
        HEADER_MAP.each_value do |attr|
          instance_variable_set(:"@#{attr}", kwargs[attr])
        end
      end

      # Builds a ResponseHeaders from raw HTTP response headers.
      #
      # @param headers [Hash, #[]] header lookup (case-insensitive string keys)
      # @return [ResponseHeaders]
      def self.from_http_headers(headers)
        attrs = {}
        HEADER_MAP.each do |header_name, attr|
          raw = headers[header_name]
          next if raw.nil?

          attrs[attr] = parse_header_value(attr, raw)
        end
        new(**attrs)
      end

      def self.parse_header_value(attr, raw)
        if INTEGER_FIELDS.include?(attr) then parse_int(raw)
        elsif FLOAT_FIELDS.include?(attr) then parse_float(raw)
        else raw.to_s
        end
      end

      def self.parse_int(value)
        Integer(value)
      rescue ArgumentError, TypeError
        nil
      end

      def self.parse_float(value)
        Float(value)
      rescue ArgumentError, TypeError
        nil
      end

      private_class_method :parse_int, :parse_float
    end
  end
end
