# frozen_string_literal: true

require_relative 'cloudlayerio/version'
require_relative 'cloudlayerio/errors'
require_relative 'cloudlayerio/configuration'
require_relative 'cloudlayerio/client'

# Official Ruby SDK for the CloudLayer.io document generation API.
#
# @example Basic usage
#   client = CloudLayerio::Client.new { |c| c.api_key = "your-api-key" }
#   result = client.url_to_pdf(url: "https://example.com")
module CloudLayerio
end
