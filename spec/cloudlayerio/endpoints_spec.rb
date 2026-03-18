# frozen_string_literal: true

RSpec.describe 'CloudLayerio Composite Endpoint Options' do
  describe CloudLayerio::Options::UrlToPdfOptions do
    it 'composes UrlOptions + PdfOptions + PuppeteerOptions + BaseOptions' do
      opts = described_class.new(
        url: 'https://example.com',
        print_background: true,
        format: 'a4',
        prefer_css_page_size: true,
        wait_until: 'networkidle2',
        name: 'test-job',
        timeout: 30_000
      )
      h = opts.to_h
      expect(h).to eq(
        'url' => 'https://example.com',
        'printBackground' => true,
        'format' => 'a4',
        'preferCSSPageSize' => true,
        'waitUntil' => 'networkidle2',
        'name' => 'test-job',
        'timeout' => 30_000
      )
    end

    it 'serializes to flat JSON (no nested option groups)' do
      opts = described_class.new(url: 'https://example.com', format: 'letter')
      h = opts.to_h
      expect(h).not_to have_key('urlOptions')
      expect(h).not_to have_key('pdfOptions')
      expect(h).not_to have_key('puppeteerOptions')
      expect(h).not_to have_key('baseOptions')
    end
  end

  describe CloudLayerio::Options::UrlToImageOptions do
    it 'composes URL + Image + Puppeteer + Base' do
      opts = described_class.new(url: 'https://example.com', image_type: 'png', quality: 90)
      h = opts.to_h
      expect(h['url']).to eq('https://example.com')
      expect(h['imageType']).to eq('png')
      expect(h['quality']).to eq(90)
    end
  end

  describe CloudLayerio::Options::HtmlToPdfOptions do
    it 'composes HTML + PDF + Puppeteer + Base' do
      html = CloudLayerio::Util::HtmlUtil.encode_html('<h1>Test</h1>')
      opts = described_class.new(html: html, format: 'a4', print_background: true)
      h = opts.to_h
      expect(h['html']).to eq(html)
      expect(h['format']).to eq('a4')
    end
  end

  describe CloudLayerio::Options::HtmlToImageOptions do
    it 'composes HTML + Image + Puppeteer + Base' do
      opts = described_class.new(html: 'PGgxPg==', image_type: 'jpeg')
      expect(opts.to_h['imageType']).to eq('jpeg')
    end
  end

  describe CloudLayerio::Options::TemplateToPdfOptions do
    it 'composes Template + PDF + Puppeteer + Base' do
      opts = described_class.new(template_id: 'tmpl-1', data: { 'name' => 'John' }, format: 'letter')
      h = opts.to_h
      expect(h['templateId']).to eq('tmpl-1')
      expect(h['data']).to eq('name' => 'John')
      expect(h['format']).to eq('letter')
    end

    it 'does not duplicate name field' do
      opts = described_class.new(name: 'my-doc')
      h = opts.to_h
      expect(h.count { |k, _| k == 'name' }).to eq(1)
    end
  end

  describe CloudLayerio::Options::TemplateToImageOptions do
    it 'composes Template + Image + Puppeteer + Base' do
      opts = described_class.new(template_id: 'tmpl-1', image_type: 'webp')
      expect(opts.to_h['templateId']).to eq('tmpl-1')
      expect(opts.to_h['imageType']).to eq('webp')
    end
  end

  describe CloudLayerio::Options::DocxToPdfOptions do
    it 'has file + BaseOptions fields' do
      opts = described_class.new(file: '/path/to/doc.docx', name: 'converted')
      h = opts.to_h
      expect(h['file']).to eq('/path/to/doc.docx')
      expect(h['name']).to eq('converted')
    end
  end

  describe CloudLayerio::Options::DocxToHtmlOptions do
    it 'has file + BaseOptions fields' do
      opts = described_class.new(file: '/path/to/doc.docx')
      expect(opts.to_h['file']).to eq('/path/to/doc.docx')
    end
  end

  describe CloudLayerio::Options::PdfToDocxOptions do
    it 'has file + BaseOptions fields' do
      opts = described_class.new(file: '/path/to/doc.pdf')
      expect(opts.to_h['file']).to eq('/path/to/doc.pdf')
    end
  end

  describe CloudLayerio::Options::MergePdfsOptions do
    it 'composes UrlOptions + BaseOptions' do
      batch = CloudLayerio::Options::Batch.new(urls: ['https://a.com/1.pdf', 'https://b.com/2.pdf'])
      opts = described_class.new(batch: batch, name: 'merged')
      h = opts.to_h
      expect(h['batch']).to eq('urls' => ['https://a.com/1.pdf', 'https://b.com/2.pdf'])
      expect(h['name']).to eq('merged')
    end
  end

  describe 'no field collisions' do
    # Verify that composing option groups does not create duplicate keys
    [
      CloudLayerio::Options::UrlToPdfOptions,
      CloudLayerio::Options::UrlToImageOptions,
      CloudLayerio::Options::HtmlToPdfOptions,
      CloudLayerio::Options::HtmlToImageOptions,
      CloudLayerio::Options::TemplateToPdfOptions,
      CloudLayerio::Options::TemplateToImageOptions,
      CloudLayerio::Options::MergePdfsOptions
    ].each do |klass|
      it "#{klass.name} has no duplicate JSON keys" do
        json_keys = klass.fields.values.map { |opts| opts[:json_key] }
        expect(json_keys).to eq(json_keys.uniq)
      end
    end
  end
end
