# frozen_string_literal: true

module CloudLayerio
  module Api
    # Conversion API methods mixed into Client.
    # Each method accepts keyword arguments, validates input, serializes to
    # camelCase JSON, and returns a ConversionResult.
    module Conversion
      # Converts a URL to PDF.
      # @param url [String] URL to convert (mutually exclusive with batch)
      # @param batch [Hash, Options::Batch] batch of URLs (max 20)
      # @option opts [String] :format PDF page format ("a4", "letter", etc.)
      # @option opts [Boolean] :print_background include background graphics
      # @return [Responses::ConversionResult] Job (v2) or binary data (v1)
      # @raise [ValidationError] if url/batch validation fails
      def url_to_pdf(**opts)
        Validation.validate_url_options(opts)
        post_conversion('/url/pdf', opts)
      end

      # Converts a URL to image.
      # @param url [String] URL to convert
      # @option opts [String] :image_type "png", "jpeg", "webp", "svg"
      # @option opts [Integer] :quality 0-100 (JPEG/WebP only)
      # @return [Responses::ConversionResult]
      # @raise [ValidationError] if validation fails
      def url_to_image(**opts)
        Validation.validate_url_options(opts)
        Validation.validate_image_options(opts)
        post_conversion('/url/image', opts)
      end

      # Converts Base64-encoded HTML to PDF.
      # @param html [String] Base64-encoded HTML (use HtmlUtil.encode_html)
      # @return [Responses::ConversionResult]
      # @raise [ValidationError] if html is empty
      # @see CloudLayerio::Util::HtmlUtil.encode_html
      def html_to_pdf(**opts)
        Validation.validate_html_options(opts)
        post_conversion('/html/pdf', opts)
      end

      # Converts Base64-encoded HTML to image.
      # @param html [String] Base64-encoded HTML
      # @return [Responses::ConversionResult]
      # @raise [ValidationError] if html is empty
      def html_to_image(**opts)
        Validation.validate_html_options(opts)
        Validation.validate_image_options(opts)
        post_conversion('/html/image', opts)
      end

      # Renders a server-side template to PDF.
      # @param template_id [String] template ID (mutually exclusive with template)
      # @param template [String] Base64-encoded template (mutually exclusive with template_id)
      # @param data [Hash] template variables
      # @return [Responses::ConversionResult]
      # @raise [ValidationError] if neither template_id nor template provided
      def template_to_pdf(**opts)
        Validation.validate_template_options(opts)
        post_conversion('/template/pdf', opts)
      end

      # Renders a server-side template to image.
      # @param template_id [String] template ID
      # @param data [Hash] template variables
      # @return [Responses::ConversionResult]
      # @raise [ValidationError] if validation fails
      def template_to_image(**opts)
        Validation.validate_template_options(opts)
        Validation.validate_image_options(opts)
        post_conversion('/template/image', opts)
      end

      # Converts a DOCX file to PDF via multipart upload.
      # @param file [String, IO] file path, IO object, or binary string
      # @return [Responses::ConversionResult]
      # @raise [ValidationError] if file is nil
      def docx_to_pdf(file:, **opts)
        Validation.validate_file_options(opts.merge(file: file))
        post_file_conversion('/docx/pdf', file, opts)
      end

      # Converts a DOCX file to HTML via multipart upload.
      # @param file [String, IO] file path, IO object, or binary string
      # @return [Responses::ConversionResult]
      def docx_to_html(file:, **opts)
        Validation.validate_file_options(opts.merge(file: file))
        post_file_conversion('/docx/html', file, opts)
      end

      # Converts a PDF file to DOCX via multipart upload.
      # @param file [String, IO] file path, IO object, or binary string
      # @return [Responses::ConversionResult]
      def pdf_to_docx(file:, **opts)
        Validation.validate_file_options(opts.merge(file: file))
        post_file_conversion('/pdf/docx', file, opts)
      end

      # Merges multiple PDFs from URLs into a single PDF.
      # @param url [String] single PDF URL
      # @param batch [Hash, Options::Batch] batch of PDF URLs
      # @return [Responses::ConversionResult]
      # @raise [ValidationError] if url/batch validation fails
      def merge_pdfs(**opts)
        Validation.validate_url_options(opts)
        post_conversion('/pdf/merge', opts)
      end

      private

      def post_conversion(path, opts)
        body = serialize_options(opts)
        result = transport.post_json(path, body, retryable: false)
        build_conversion_result(result)
      end

      def post_file_conversion(path, file, opts)
        content, filename = Http::Multipart.read_file(file)
        parts = [{ name: 'file', value: content, filename: filename }]
        serialize_options(opts).each do |key, value|
          parts << { name: key, value: value.is_a?(Hash) ? JSON.generate(value) : value.to_s }
        end
        result = transport.post_multipart(path, parts, retryable: false)
        build_conversion_result(result)
      end

      def serialize_options(opts)
        hash = {}
        opts.each do |key, value|
          next if value.equal?(NOT_SET)

          camel_key = Util::JsonSerializer.snake_to_camel(key)
          hash[camel_key] = serialize_opt_value(value)
        end
        hash
      end

      def serialize_opt_value(value)
        if value.respond_to?(:to_h) && value.class.respond_to?(:fields)
          value.to_h
        elsif value.is_a?(Hash)
          Util::JsonSerializer.serialize(value)
        elsif value.is_a?(Array)
          value.map { |v| serialize_opt_value(v) }
        else
          value
        end
      end

      def build_conversion_result(result)
        data = if result[:data].is_a?(Hash)
                 Responses::Job.from_hash(result[:data])
               else
                 result[:data]
               end
        Responses::ConversionResult.new(
          data: data,
          headers: result[:headers],
          status: result[:status],
          filename: result[:filename]
        )
      end
    end
  end
end
