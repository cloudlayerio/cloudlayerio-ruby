# frozen_string_literal: true

module CloudLayerio
  module Options
    # PDF-specific rendering options.
    class PdfOptions
      include OptionBase

      field :print_background, json_key: 'printBackground'
      field :format
      field :margin
      field :header_template, json_key: 'headerTemplate'
      field :footer_template, json_key: 'footerTemplate'
      field :generate_preview, json_key: 'generatePreview'
    end
  end
end
