# frozen_string_literal: true

module CloudLayerio
  module Options
    # Composite endpoint options. Each class composes fields from the relevant
    # option groups into a flat structure that serializes to flat camelCase JSON.

    class UrlToPdfOptions
      include OptionBase

      compose UrlOptions, PdfOptions, PuppeteerOptions, BaseOptions
    end

    class UrlToImageOptions
      include OptionBase

      compose UrlOptions, ImageOptions, PuppeteerOptions, BaseOptions
    end

    class HtmlToPdfOptions
      include OptionBase

      compose HtmlOptions, PdfOptions, PuppeteerOptions, BaseOptions
    end

    class HtmlToImageOptions
      include OptionBase

      compose HtmlOptions, ImageOptions, PuppeteerOptions, BaseOptions
    end

    class TemplateToPdfOptions
      include OptionBase

      compose TemplateOptions, PdfOptions, PuppeteerOptions, BaseOptions
    end

    class TemplateToImageOptions
      include OptionBase

      compose TemplateOptions, ImageOptions, PuppeteerOptions, BaseOptions
    end

    class DocxToPdfOptions
      include OptionBase

      field :file
      compose BaseOptions
    end

    class DocxToHtmlOptions
      include OptionBase

      field :file
      compose BaseOptions
    end

    class PdfToDocxOptions
      include OptionBase

      field :file
      compose BaseOptions
    end

    class MergePdfsOptions
      include OptionBase

      compose UrlOptions, BaseOptions
    end
  end
end
