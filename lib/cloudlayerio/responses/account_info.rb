# frozen_string_literal: true

module CloudLayerio
  module Responses
    # Represents account information from the CloudLayer.io API.
    # Unknown fields are stored in the `extra` hash for forward compatibility.
    class AccountInfo
      KNOWN_FIELDS = %i[
        email calls_limit calls storage_used storage_limit
        subscription bytes_total bytes_limit compute_time_total
        compute_time_limit sub_type uid credit sub_active
      ].freeze

      JSON_TO_ATTR = {
        'callsLimit' => :calls_limit,
        'storageUsed' => :storage_used,
        'storageLimit' => :storage_limit,
        'bytesTotal' => :bytes_total,
        'bytesLimit' => :bytes_limit,
        'computeTimeTotal' => :compute_time_total,
        'computeTimeLimit' => :compute_time_limit,
        'subType' => :sub_type,
        'subActive' => :sub_active
      }.freeze

      attr_reader(*KNOWN_FIELDS, :extra)

      def initialize(**kwargs)
        @extra = {}
        KNOWN_FIELDS.each do |f|
          instance_variable_set(:"@#{f}", kwargs[f])
        end
        kwargs.each do |k, v|
          @extra[k] = v unless KNOWN_FIELDS.include?(k)
        end
      end

      # Parses AccountInfo from a camelCase JSON hash (string keys).
      #
      # @param hash [Hash] parsed JSON with string keys
      # @return [AccountInfo]
      def self.from_hash(hash)
        attrs = {}
        hash.each do |key, value|
          attr = JSON_TO_ATTR[key] || Util::JsonSerializer.camel_to_snake(key).to_sym
          attrs[attr] = value
        end
        new(**attrs)
      end

      # Access extra (unknown) fields by key.
      #
      # @param key [Symbol, String]
      # @return [Object, nil]
      def [](key)
        sym = key.to_sym
        return send(sym) if KNOWN_FIELDS.include?(sym)

        @extra[sym]
      end
    end
  end
end
