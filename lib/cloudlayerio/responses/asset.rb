# frozen_string_literal: true

module CloudLayerio
  module Responses
    # Represents a CloudLayer.io asset (generated file).
    class Asset
      FIELDS = %i[
        uid id file_id preview_file_id type ext preview_ext
        url preview_url size timestamp project_id job_id name
      ].freeze

      JSON_TO_ATTR = {
        'fileId' => :file_id,
        'previewFileId' => :preview_file_id,
        'previewExt' => :preview_ext,
        'previewUrl' => :preview_url,
        'projectId' => :project_id,
        'jobId' => :job_id
      }.freeze

      attr_reader(*FIELDS)

      def initialize(**kwargs)
        FIELDS.each do |f|
          instance_variable_set(:"@#{f}", kwargs[f])
        end
      end

      # Parses an Asset from a camelCase JSON hash (string keys).
      #
      # @param hash [Hash] parsed JSON with string keys
      # @return [Asset]
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
    end
  end
end
