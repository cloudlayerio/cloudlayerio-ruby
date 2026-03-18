# frozen_string_literal: true

module CloudLayerio
  module Util
    # Converts between Ruby snake_case and JSON camelCase,
    # and handles serialization/deserialization of option and response hashes.
    module JsonSerializer
      # Non-standard mappings that a naive converter would get wrong.
      # preferCSSPageSize has consecutive capitals; a naive snake_to_camel
      # produces "preferCssPageSize" which the API rejects.
      SNAKE_TO_CAMEL_OVERRIDES = {
        'prefer_css_page_size' => 'preferCSSPageSize'
      }.freeze

      CAMEL_TO_SNAKE_OVERRIDES = {
        'preferCSSPageSize' => 'prefer_css_page_size'
      }.freeze

      module_function

      # Converts a snake_case string to camelCase.
      #
      # @param key [String, Symbol]
      # @return [String]
      def snake_to_camel(key)
        str = key.to_s
        return SNAKE_TO_CAMEL_OVERRIDES[str] if SNAKE_TO_CAMEL_OVERRIDES.key?(str)

        parts = str.split('_')
        parts[0] + parts[1..].map(&:capitalize).join
      end

      # Converts a camelCase string to snake_case.
      #
      # @param key [String, Symbol]
      # @return [String]
      def camel_to_snake(key)
        str = key.to_s
        return CAMEL_TO_SNAKE_OVERRIDES[str] if CAMEL_TO_SNAKE_OVERRIDES.key?(str)

        str.gsub(/([A-Z])/, '_\1').downcase.sub(/\A_/, '')
      end

      # Deep-converts a snake_case hash to camelCase, omitting nil values.
      # Recursively processes nested hashes and arrays.
      #
      # @param hash [Hash]
      # @return [Hash]
      def serialize(hash)
        result = {}
        hash.each do |key, value|
          camel_key = snake_to_camel(key)
          result[camel_key] = serialize_value(value)
        end
        result
      end

      # Deep-converts a camelCase hash to snake_case for response parsing.
      #
      # @param hash [Hash]
      # @return [Hash]
      def deserialize(hash)
        result = {}
        hash.each do |key, value|
          snake_key = camel_to_snake(key)
          result[snake_key] = deserialize_value(value)
        end
        result
      end

      # Serializes a single value, recursing into nested structures.
      #
      # @param value [Object]
      # @return [Object]
      def serialize_value(value)
        case value
        when Hash
          serialize(value)
        when Array
          value.map { |v| serialize_value(v) }
        else
          value
        end
      end

      # Deserializes a single value, recursing into nested structures.
      #
      # @param value [Object]
      # @return [Object]
      def deserialize_value(value)
        case value
        when Hash
          deserialize(value)
        when Array
          value.map { |v| deserialize_value(v) }
        else
          value
        end
      end
    end
  end
end
