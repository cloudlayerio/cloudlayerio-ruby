# frozen_string_literal: true

module CloudLayerio
  module Options
    # Options for URL-based conversions.
    class UrlOptions
      include OptionBase

      field :url
      field :authentication
      field :batch
      field :cookies
    end

    # Options for raw HTML conversions. HTML must be Base64-encoded.
    class HtmlOptions
      include OptionBase

      field :html
    end

    # Options for template-based conversions.
    class TemplateOptions
      include OptionBase

      field :template_id, json_key: 'templateId'
      field :template
      field :data
      field :name
    end
  end
end
