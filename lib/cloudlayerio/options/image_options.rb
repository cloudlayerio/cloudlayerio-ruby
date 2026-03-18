# frozen_string_literal: true

module CloudLayerio
  module Options
    # Image-specific rendering options.
    class ImageOptions
      include OptionBase

      field :image_type, json_key: 'imageType'
      field :quality
      field :trim
      field :transparent
      field :generate_preview, json_key: 'generatePreview'
    end
  end
end
