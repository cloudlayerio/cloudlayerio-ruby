# frozen_string_literal: true

module CloudLayerio
  # API version constants used in URL path construction and client configuration.
  module ApiVersion
    V1 = 'v1'
    V2 = 'v2'

    ALL = [V1, V2].freeze

    module_function

    def resolve(value)
      return value if ALL.include?(value)
      return value.to_s if value.is_a?(Symbol) && ALL.include?(value.to_s)

      value.to_s
    end
  end

  # PDF page format constants.
  module PdfFormat
    LETTER  = 'letter'
    LEGAL   = 'legal'
    TABLOID = 'tabloid'
    LEDGER  = 'ledger'
    A0 = 'a0'
    A1 = 'a1'
    A2 = 'a2'
    A3 = 'a3'
    A4 = 'a4'
    A5 = 'a5'
    A6 = 'a6'

    ALL = [LETTER, LEGAL, TABLOID, LEDGER, A0, A1, A2, A3, A4, A5, A6].freeze

    module_function

    def resolve(value)
      return value if value.is_a?(String)

      value.to_s
    end
  end

  # Image output type constants.
  module ImageType
    PNG  = 'png'
    JPEG = 'jpeg'
    JPG  = 'jpg'
    WEBP = 'webp'
    SVG  = 'svg'

    ALL = [PNG, JPEG, JPG, WEBP, SVG].freeze

    module_function

    def resolve(value)
      return value if value.is_a?(String)

      value.to_s
    end
  end

  # Job status constants returned by the API.
  module JobStatus
    PENDING = 'pending'
    SUCCESS = 'success'
    ERROR   = 'error'

    ALL = [PENDING, SUCCESS, ERROR].freeze
  end

  # Job type constants identifying the conversion performed.
  module JobType
    HTML_PDF      = 'html-pdf'
    HTML_IMAGE    = 'html-image'
    URL_PDF       = 'url-pdf'
    URL_IMAGE     = 'url-image'
    TEMPLATE_PDF  = 'template-pdf'
    TEMPLATE_IMAGE = 'template-image'
    DOCX_PDF      = 'docx-pdf'
    DOCX_HTML     = 'docx-html'
    IMAGE_PDF     = 'image-pdf'
    PDF_IMAGE     = 'pdf-image'
    PDF_DOCX      = 'pdf-docx'
    PDF_MERGE     = 'merge-pdf'

    ALL = [
      HTML_PDF, HTML_IMAGE, URL_PDF, URL_IMAGE,
      TEMPLATE_PDF, TEMPLATE_IMAGE, DOCX_PDF, DOCX_HTML,
      IMAGE_PDF, PDF_IMAGE, PDF_DOCX, PDF_MERGE
    ].freeze
  end

  # Browser wait-until event constants for Puppeteer navigation.
  module WaitUntilOption
    LOAD = 'load'
    DOM_CONTENT_LOADED = 'domcontentloaded'
    NETWORK_IDLE_0    = 'networkidle0'
    NETWORK_IDLE_2    = 'networkidle2'

    ALL = [LOAD, DOM_CONTENT_LOADED, NETWORK_IDLE_0, NETWORK_IDLE_2].freeze

    module_function

    def resolve(value)
      return value if value.is_a?(String)

      value.to_s
    end
  end

  # Freeze all constant modules to prevent runtime modification.
  [ApiVersion, PdfFormat, ImageType, JobStatus, JobType, WaitUntilOption].each(&:freeze)
end
