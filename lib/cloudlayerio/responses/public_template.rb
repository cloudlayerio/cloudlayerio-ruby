# frozen_string_literal: true

module CloudLayerio
  module Responses
    # A public template from the CloudLayer.io template gallery.
    # Unknown fields are stored in `extra` for forward compatibility.
    class PublicTemplate
      KNOWN_FIELDS = %i[
        id template_id title short_description search_keywords tags
        category type preview_url example_asset_url highlights
        timestamp project_id sample_data author_name
      ].freeze

      JSON_TO_ATTR = {
        'templateId' => :template_id,
        'shortDescription' => :short_description,
        'searchKeywords' => :search_keywords,
        'previewUrl' => :preview_url,
        'exampleAssetUrl' => :example_asset_url,
        'projectId' => :project_id,
        'sampleData' => :sample_data,
        'authorName' => :author_name
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

      # Parses a PublicTemplate from a camelCase JSON hash (string keys).
      #
      # @param hash [Hash] parsed JSON with string keys
      # @return [PublicTemplate]
      def self.from_hash(hash)
        attrs = {}
        hash.each do |key, value|
          attr = JSON_TO_ATTR[key] || Util::JsonSerializer.camel_to_snake(key).to_sym
          attrs[attr] = value
        end
        new(**attrs)
      end
    end
  end
end
