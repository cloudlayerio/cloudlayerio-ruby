# frozen_string_literal: true

module CloudLayerio
  # Sentinel value distinguishing "not provided" from nil.
  # Used for emulate_media_type which has three states:
  # NOT_SET (omit from JSON), nil (send JSON null), string value.
  NOT_SET = Object.new.freeze

  module Options
    # Shared module for option classes. Provides:
    # - Declarative field definitions via `field`
    # - Keyword argument initializer
    # - `#to_h` serialization to camelCase hash (nil/NOT_SET fields omitted)
    # - `compose` to pull fields from other option classes
    module OptionBase
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def fields
          @fields ||= {}
        end

        # Declares a field on the option class.
        #
        # @param name [Symbol] snake_case field name
        # @param json_key [String, nil] override camelCase JSON key (auto-derived if nil)
        def field(name, json_key: nil)
          key = json_key || Util::JsonSerializer.snake_to_camel(name)
          fields[name] = { json_key: key }
          attr_reader name
        end

        # Copies all field definitions from the given option classes.
        # Used by composite endpoint options to merge multiple option groups.
        #
        # @param klasses [Array<Class>] option classes to compose from
        def compose(*klasses)
          klasses.each do |klass|
            klass.fields.each do |name, opts|
              next if fields.key?(name) # skip duplicates (e.g., `name` in both Template and Base)

              fields[name] = opts
              attr_reader name
            end
          end
        end
      end

      # Initializes the option from keyword arguments.
      # Unknown keys raise ArgumentError. Absent fields default to NOT_SET.
      def initialize(**kwargs)
        unknown = kwargs.keys - self.class.fields.keys
        raise ArgumentError, "Unknown field(s): #{unknown.join(', ')}" if unknown.any?

        self.class.fields.each_key do |name|
          instance_variable_set(:"@#{name}", kwargs.fetch(name, NOT_SET))
        end
      end

      # Serializes to a camelCase hash suitable for JSON encoding.
      # NOT_SET fields are omitted. nil fields are included as JSON null.
      # Nested option objects are recursively serialized.
      #
      # @return [Hash]
      def to_h
        result = {}
        self.class.fields.each do |name, opts|
          value = instance_variable_get(:"@#{name}")
          next if value.equal?(NOT_SET)

          result[opts[:json_key]] = self.class.serialize_field(value)
        end
        result
      end

      module ClassMethods
        def serialize_field(value)
          case value
          when ->(v) { v.respond_to?(:to_h) && v.class.respond_to?(:fields) }
            value.to_h
          when Hash
            Util::JsonSerializer.serialize(value)
          when Array
            value.map { |v| serialize_field(v) }
          else
            value
          end
        end
      end
    end
  end
end
