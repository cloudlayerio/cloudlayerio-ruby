# frozen_string_literal: true

RSpec.describe CloudLayerio::Util::JsonSerializer do
  describe '.snake_to_camel' do
    it 'converts simple snake_case' do
      expect(described_class.snake_to_camel('print_background')).to eq('printBackground')
    end

    it 'converts multi-word snake_case' do
      expect(described_class.snake_to_camel('wait_for_frame_attachment')).to eq('waitForFrameAttachment')
    end

    it 'handles single word' do
      expect(described_class.snake_to_camel('format')).to eq('format')
    end

    it 'handles preferCSSPageSize override' do
      expect(described_class.snake_to_camel('prefer_css_page_size')).to eq('preferCSSPageSize')
    end

    it 'accepts symbols' do
      expect(described_class.snake_to_camel(:print_background)).to eq('printBackground')
    end
  end

  describe '.camel_to_snake' do
    it 'converts simple camelCase' do
      expect(described_class.camel_to_snake('printBackground')).to eq('print_background')
    end

    it 'converts multi-word camelCase' do
      expect(described_class.camel_to_snake('waitForFrameAttachment')).to eq('wait_for_frame_attachment')
    end

    it 'handles single word' do
      expect(described_class.camel_to_snake('format')).to eq('format')
    end

    it 'handles preferCSSPageSize override' do
      expect(described_class.camel_to_snake('preferCSSPageSize')).to eq('prefer_css_page_size')
    end
  end

  describe 'round-trip' do
    %w[
      printBackground viewPort templateId imageType httpOnly sameSite
      headerTemplate footerTemplate apiVer projectId assetUrl previewUrl
      workerName processTime preferCSSPageSize deviceScaleFactor
      isMobile hasTouch isLandscape waitForSelector autoScroll
      pageRanges timeZone emulateMediaType generatePreview
      maintainAspectRatio waitForFrameNavigation templateString
      accessKeyId secretAccessKey callsLimit subType subActive
    ].each do |key|
      it "round-trips #{key}" do
        snake = described_class.camel_to_snake(key)
        expect(described_class.snake_to_camel(snake)).to eq(key)
      end
    end
  end

  describe '.serialize' do
    it 'converts snake_case hash to camelCase' do
      input = { 'print_background' => true, 'format' => 'a4' }
      expect(described_class.serialize(input)).to eq('printBackground' => true, 'format' => 'a4')
    end

    it 'deep-converts nested hashes' do
      input = { 'margin' => { 'top' => '10px', 'bottom' => '20px' } }
      expect(described_class.serialize(input)).to eq('margin' => { 'top' => '10px', 'bottom' => '20px' })
    end

    it 'deep-converts arrays of hashes' do
      input = { 'cookies' => [{ 'http_only' => true }] }
      expect(described_class.serialize(input)).to eq('cookies' => [{ 'httpOnly' => true }])
    end
  end

  describe '.deserialize' do
    it 'converts camelCase hash to snake_case' do
      input = { 'printBackground' => true, 'format' => 'a4' }
      expect(described_class.deserialize(input)).to eq('print_background' => true, 'format' => 'a4')
    end

    it 'deep-converts nested hashes' do
      input = { 'assetUrl' => 'https://example.com', 'params' => { 'templateId' => 'abc' } }
      result = described_class.deserialize(input)
      expect(result['asset_url']).to eq('https://example.com')
      expect(result['params']['template_id']).to eq('abc')
    end
  end
end
