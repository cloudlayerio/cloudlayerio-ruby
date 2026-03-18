# frozen_string_literal: true

module CloudLayerio
  module Options
    # Page margin dimensions. Values can be strings ("10px", "1in") or numbers (pixels).
    class Margin
      include OptionBase

      field :top
      field :bottom
      field :left
      field :right
    end

    # Browser viewport configuration.
    class Viewport
      include OptionBase

      field :width
      field :height
      field :device_scale_factor, json_key: 'deviceScaleFactor'
      field :is_mobile, json_key: 'isMobile'
      field :has_touch, json_key: 'hasTouch'
      field :is_landscape, json_key: 'isLandscape'
    end

    # Browser cookie for URL-based conversions.
    class Cookie
      include OptionBase

      field :name
      field :value
      field :url
      field :domain
      field :path
      field :expires
      field :http_only, json_key: 'httpOnly'
      field :secure
      field :same_site, json_key: 'sameSite'
    end

    # HTTP Basic authentication credentials.
    class Authentication
      include OptionBase

      field :username
      field :password
    end

    # Batch of URLs for multi-URL conversions.
    class Batch
      include OptionBase

      field :urls
    end

    # Header/footer template configuration for PDF generation.
    class HeaderFooterTemplate
      include OptionBase

      field :method
      field :selector
      field :margin
      field :style
      field :image_style, json_key: 'imageStyle'
      field :template
      field :template_string, json_key: 'templateString'
    end

    # Preview image generation options.
    class PreviewOptions
      include OptionBase

      field :width
      field :height
      field :type
      field :quality
      field :maintain_aspect_ratio, json_key: 'maintainAspectRatio'
    end

    # Options for waiting on a CSS selector before capture.
    class WaitForSelectorOptions
      include OptionBase

      field :selector
      field :options
    end
  end
end
