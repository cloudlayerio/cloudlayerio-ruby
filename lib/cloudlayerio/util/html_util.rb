# frozen_string_literal: true

require 'base64'

module CloudLayerio
  module Util
    # Utility for encoding HTML strings for the CloudLayer.io API.
    module HtmlUtil
      module_function

      # Base64-encodes an HTML string for use with html_to_pdf / html_to_image.
      #
      # @param html [String] raw HTML string
      # @return [String] Base64-encoded string (strict, no newlines)
      def encode_html(html)
        Base64.strict_encode64(html)
      end
    end
  end
end
