# frozen_string_literal: true

require_relative 'cloudlayerio/version'
require_relative 'cloudlayerio/errors'
require_relative 'cloudlayerio/constants'

# Utilities (must load before options/responses that depend on them)
require_relative 'cloudlayerio/util/json_serializer'
require_relative 'cloudlayerio/util/html_util'

# Options
require_relative 'cloudlayerio/options/option_base'
require_relative 'cloudlayerio/options/components'
require_relative 'cloudlayerio/options/pdf_options'
require_relative 'cloudlayerio/options/image_options'
require_relative 'cloudlayerio/options/puppeteer_options'
require_relative 'cloudlayerio/options/source_options'
require_relative 'cloudlayerio/options/base_options'
require_relative 'cloudlayerio/options/endpoints'

# Responses
require_relative 'cloudlayerio/responses/response_headers'
require_relative 'cloudlayerio/responses/job'
require_relative 'cloudlayerio/responses/asset'
require_relative 'cloudlayerio/responses/account_info'
require_relative 'cloudlayerio/responses/storage'
require_relative 'cloudlayerio/responses/status_response'
require_relative 'cloudlayerio/responses/public_template'
require_relative 'cloudlayerio/responses/conversion_result'

# HTTP transport
require_relative 'cloudlayerio/http/retry_policy'
require_relative 'cloudlayerio/http/multipart'
require_relative 'cloudlayerio/http/error_mapper'
require_relative 'cloudlayerio/http/transport'

# API modules
require_relative 'cloudlayerio/api/validation'
require_relative 'cloudlayerio/api/conversion'
require_relative 'cloudlayerio/api/data_management'

require_relative 'cloudlayerio/configuration'
require_relative 'cloudlayerio/client'

# Official Ruby SDK for the CloudLayer.io document generation API.
#
# @example Basic usage
#   client = CloudLayerio::Client.new { |c| c.api_key = "your-api-key" }
#   result = client.url_to_pdf(url: "https://example.com")
module CloudLayerio
end
