# frozen_string_literal: true

RSpec.describe CloudLayerio::Api::Conversion do
  let(:client) { CloudLayerio::Client.new(api_key: 'test-key', api_version: :v2) }

  def stub_conversion(path, response_body: '{"id":"job-1","status":"pending"}', status: 200,
                       content_type: 'application/json', extra_headers: {})
    headers = { 'Content-Type' => content_type }.merge(extra_headers)
    stub_request(:post, "https://api.cloudlayer.io/v2#{path}")
      .to_return(status: status, body: response_body, headers: headers)
  end

  describe '#url_to_pdf' do
    it 'sends POST to /url/pdf with serialized options' do
      stub = stub_conversion('/url/pdf')
      result = client.url_to_pdf(url: 'https://example.com', format: 'a4', print_background: true)

      expect(stub).to have_been_requested
      expect(result).to be_a(CloudLayerio::Responses::ConversionResult)
      expect(result.job?).to be true
      expect(result.job.id).to eq('job-1')
    end

    it 'returns binary ConversionResult for v1' do
      v1_client = CloudLayerio::Client.new(api_key: 'test', api_version: :v1)
      stub_request(:post, 'https://api.cloudlayer.io/v1/url/pdf')
        .to_return(
          status: 200,
          body: 'PDF-binary-data',
          headers: {
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename="output.pdf"'
          }
        )

      result = v1_client.url_to_pdf(url: 'https://example.com')
      expect(result.binary?).to be true
      expect(result.bytes).to eq('PDF-binary-data')
      expect(result.filename).to eq('output.pdf')
    end

    it 'validates url required' do
      expect { client.url_to_pdf }.to raise_error(CloudLayerio::ValidationError, /url or batch/)
    end

    it 'serializes nested option objects' do
      stub = stub_conversion('/url/pdf')
      margin = CloudLayerio::Options::Margin.new(top: '10px', bottom: '20px')
      client.url_to_pdf(url: 'https://example.com', margin: margin)

      expect(stub.with(body: hash_including('margin' => { 'top' => '10px', 'bottom' => '20px' })))
        .to have_been_requested
    end

    it 'serializes batch urls' do
      stub = stub_conversion('/url/pdf')
      batch = CloudLayerio::Options::Batch.new(urls: ['https://a.com', 'https://b.com'])
      client.url_to_pdf(batch: batch)

      expect(stub.with(body: hash_including('batch' => { 'urls' => ['https://a.com', 'https://b.com'] })))
        .to have_been_requested
    end

    it 'does not retry' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(status: 500, body: '{"error":"fail"}', headers: { 'Content-Type' => 'application/json' })

      expect { client.url_to_pdf(url: 'https://example.com') }
        .to raise_error(CloudLayerio::ApiError)
    end
  end

  describe '#url_to_image' do
    it 'sends POST to /url/image' do
      stub = stub_conversion('/url/image')
      client.url_to_image(url: 'https://example.com', image_type: 'png')
      expect(stub).to have_been_requested
    end

    it 'validates quality range' do
      expect { client.url_to_image(url: 'https://example.com', quality: 150) }
        .to raise_error(CloudLayerio::ValidationError, /quality/)
    end
  end

  describe '#html_to_pdf' do
    it 'sends POST to /html/pdf' do
      stub = stub_conversion('/html/pdf')
      html = CloudLayerio::Util::HtmlUtil.encode_html('<h1>Test</h1>')
      result = client.html_to_pdf(html: html)
      expect(stub).to have_been_requested
      expect(result.job?).to be true
    end

    it 'validates html required' do
      expect { client.html_to_pdf }.to raise_error(CloudLayerio::ValidationError, /html/)
    end
  end

  describe '#html_to_image' do
    it 'sends POST to /html/image' do
      stub = stub_conversion('/html/image')
      client.html_to_image(html: 'PGgxPg==')
      expect(stub).to have_been_requested
    end
  end

  describe '#template_to_pdf' do
    it 'sends POST to /template/pdf with JSON body' do
      stub = stub_conversion('/template/pdf')
      client.template_to_pdf(template_id: 'tmpl-1', data: { 'name' => 'John' })

      expect(stub.with(body: hash_including('templateId' => 'tmpl-1', 'data' => { 'name' => 'John' })))
        .to have_been_requested
    end

    it 'validates template_id or template required' do
      expect { client.template_to_pdf }
        .to raise_error(CloudLayerio::ValidationError, /template_id or template/)
    end
  end

  describe '#template_to_image' do
    it 'sends POST to /template/image' do
      stub = stub_conversion('/template/image')
      client.template_to_image(template_id: 'tmpl-1')
      expect(stub).to have_been_requested
    end
  end

  describe '#docx_to_pdf' do
    it 'sends multipart POST to /docx/pdf' do
      stub = stub_request(:post, 'https://api.cloudlayer.io/v2/docx/pdf')
        .with(headers: { 'Content-Type' => /multipart\/form-data/ })
        .to_return(status: 200, body: '{"id":"job-1","status":"pending"}',
                   headers: { 'Content-Type' => 'application/json' })

      result = client.docx_to_pdf(file: StringIO.new('docx-bytes'), name: 'my-doc')
      expect(stub).to have_been_requested
      expect(result.job?).to be true
    end

    it 'validates file required' do
      expect { client.docx_to_pdf(file: nil) }
        .to raise_error(CloudLayerio::ValidationError, /file/)
    end
  end

  describe '#docx_to_html' do
    it 'sends multipart POST to /docx/html' do
      stub = stub_request(:post, 'https://api.cloudlayer.io/v2/docx/html')
        .with(headers: { 'Content-Type' => /multipart/ })
        .to_return(status: 200, body: '{"id":"job-2","status":"pending"}',
                   headers: { 'Content-Type' => 'application/json' })

      client.docx_to_html(file: StringIO.new('docx-bytes'))
      expect(stub).to have_been_requested
    end
  end

  describe '#pdf_to_docx' do
    it 'sends multipart POST to /pdf/docx' do
      stub = stub_request(:post, 'https://api.cloudlayer.io/v2/pdf/docx')
        .with(headers: { 'Content-Type' => /multipart/ })
        .to_return(status: 200, body: '{"id":"job-3","status":"pending"}',
                   headers: { 'Content-Type' => 'application/json' })

      client.pdf_to_docx(file: StringIO.new('pdf-bytes'))
      expect(stub).to have_been_requested
    end
  end

  describe '#merge_pdfs' do
    it 'sends POST to /pdf/merge' do
      stub = stub_request(:post, 'https://api.cloudlayer.io/v2/pdf/merge')
        .to_return(status: 200, body: '{"id":"job-4","status":"pending"}',
                   headers: { 'Content-Type' => 'application/json' })

      client.merge_pdfs(batch: { urls: ['https://a.com/1.pdf', 'https://b.com/2.pdf'] })
      expect(stub).to have_been_requested
    end

    it 'validates url or batch required' do
      expect { client.merge_pdfs }.to raise_error(CloudLayerio::ValidationError, /url or batch/)
    end
  end

  describe 'serialization' do
    it 'converts snake_case kwargs to camelCase JSON' do
      stub = stub_conversion('/url/pdf')
      client.url_to_pdf(
        url: 'https://example.com',
        print_background: true,
        prefer_css_page_size: true,
        page_ranges: '1-3',
        api_ver: 'v2'
      )

      expect(stub.with(body: hash_including(
        'url' => 'https://example.com',
        'printBackground' => true,
        'preferCSSPageSize' => true,
        'pageRanges' => '1-3',
        'apiVer' => 'v2'
      ))).to have_been_requested
    end

    it 'handles three-state emulate_media_type' do
      stub = stub_conversion('/url/pdf')
      client.url_to_pdf(url: 'https://example.com', emulate_media_type: nil)

      expect(stub.with { |req|
        body = JSON.parse(req.body)
        body.key?('emulateMediaType') && body['emulateMediaType'].nil?
      }).to have_been_requested
    end
  end
end
