# frozen_string_literal: true

module CloudLayerio
  module Options
    # Browser/Puppeteer rendering options controlling page load behavior, viewport, and scaling.
    class PuppeteerOptions
      include OptionBase

      field :wait_until, json_key: 'waitUntil'
      field :wait_for_frame, json_key: 'waitForFrame'
      field :wait_for_frame_attachment, json_key: 'waitForFrameAttachment'
      field :wait_for_frame_navigation, json_key: 'waitForFrameNavigation'
      field :wait_for_frame_images, json_key: 'waitForFrameImages'
      field :wait_for_frame_selector, json_key: 'waitForFrameSelector'
      field :wait_for_selector, json_key: 'waitForSelector'
      field :prefer_css_page_size, json_key: 'preferCSSPageSize'
      field :scale
      field :height
      field :width
      field :landscape
      field :page_ranges, json_key: 'pageRanges'
      field :auto_scroll, json_key: 'autoScroll'
      field :view_port, json_key: 'viewPort'
      field :time_zone, json_key: 'timeZone'
      field :emulate_media_type, json_key: 'emulateMediaType'
    end
  end
end
