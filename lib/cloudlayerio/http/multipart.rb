# frozen_string_literal: true

require 'securerandom'

module CloudLayerio
  module Http
    # Builds multipart/form-data request bodies for file uploads.
    # Ruby's net/http has no built-in multipart support, so this
    # constructs the body manually with correct RFC 2388 formatting.
    module Multipart
      CRLF = "\r\n"

      module_function

      # Builds a multipart form-data body from an array of parts.
      #
      # @param parts [Array<Hash>] each has :name, :value, and optionally :filename, :content_type
      # @return [Array(String, String)] [body_string, content_type_header_with_boundary]
      def build(parts)
        boundary = SecureRandom.hex(16)
        body = +''
        parts.each { |part| append_part(body, part, boundary) }
        body << "--#{boundary}--#{CRLF}"
        body.force_encoding(Encoding::BINARY)
        [body, "multipart/form-data; boundary=#{boundary}"]
      end

      # Reads file content from various input types.
      #
      # @param file [String, IO] file path, IO object, or raw bytes
      # @return [Array(String, String)] [binary_content, detected_filename]
      def read_file(file)
        case file
        when String then read_string_file(file)
        when ->(f) { f.respond_to?(:read) } then read_io_file(file)
        else raise ValidationError, "file must be a String path, IO object, or binary String (got #{file.class})"
        end
      end

      def append_part(body, part, boundary)
        body << "--#{boundary}#{CRLF}"
        if part[:filename]
          body << "Content-Disposition: form-data; name=\"#{part[:name]}\"; filename=\"#{part[:filename]}\"#{CRLF}"
          body << "Content-Type: #{part[:content_type] || 'application/octet-stream'}#{CRLF}"
        else
          body << "Content-Disposition: form-data; name=\"#{part[:name]}\"#{CRLF}"
        end
        body << CRLF << part[:value].to_s << CRLF
      end

      def read_string_file(file)
        if File.exist?(file)
          [File.binread(file), File.basename(file)]
        else
          [file.dup.force_encoding(Encoding::BINARY), 'upload']
        end
      end

      def read_io_file(file)
        content = file.read
        content = content.dup.force_encoding(Encoding::BINARY) if content.is_a?(String)
        filename = file.respond_to?(:path) ? File.basename(file.path) : 'upload'
        [content, filename]
      end

      private_class_method :append_part, :read_string_file, :read_io_file
    end
  end
end
