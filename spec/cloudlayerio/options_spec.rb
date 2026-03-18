# frozen_string_literal: true

RSpec.describe 'CloudLayerio Options' do
  describe CloudLayerio::Options::Margin do
    it 'serializes to camelCase hash' do
      margin = described_class.new(top: '10px', bottom: '1in', left: 0, right: '2cm')
      expect(margin.to_h).to eq(
        'top' => '10px', 'bottom' => '1in', 'left' => 0, 'right' => '2cm'
      )
    end

    it 'omits NOT_SET fields' do
      margin = described_class.new(top: '10px')
      expect(margin.to_h).to eq('top' => '10px')
    end

    it 'accepts numeric values (LayoutDimension)' do
      margin = described_class.new(top: 100, bottom: 50)
      expect(margin.to_h).to eq('top' => 100, 'bottom' => 50)
    end
  end

  describe CloudLayerio::Options::Viewport do
    it 'serializes with correct JSON keys' do
      vp = described_class.new(width: 1920, height: 1080, device_scale_factor: 2.0, is_mobile: false)
      h = vp.to_h
      expect(h['width']).to eq(1920)
      expect(h['deviceScaleFactor']).to eq(2.0)
      expect(h['isMobile']).to eq(false)
    end
  end

  describe CloudLayerio::Options::Cookie do
    it 'serializes with camelCase keys' do
      cookie = described_class.new(name: 'session', value: 'abc123', http_only: true, same_site: 'Strict')
      h = cookie.to_h
      expect(h).to eq(
        'name' => 'session', 'value' => 'abc123', 'httpOnly' => true, 'sameSite' => 'Strict'
      )
    end
  end

  describe CloudLayerio::Options::Authentication do
    it 'serializes credentials' do
      auth = described_class.new(username: 'user', password: 'pass')
      expect(auth.to_h).to eq('username' => 'user', 'password' => 'pass')
    end
  end

  describe CloudLayerio::Options::Batch do
    it 'serializes URL list' do
      batch = described_class.new(urls: ['https://a.com', 'https://b.com'])
      expect(batch.to_h).to eq('urls' => ['https://a.com', 'https://b.com'])
    end
  end

  describe CloudLayerio::Options::HeaderFooterTemplate do
    it 'serializes with nested margin' do
      margin = CloudLayerio::Options::Margin.new(top: '10px')
      hft = described_class.new(method: 'template', template_string: '<div>Page</div>', margin: margin)
      h = hft.to_h
      expect(h['method']).to eq('template')
      expect(h['templateString']).to eq('<div>Page</div>')
      expect(h['margin']).to eq('top' => '10px')
    end
  end

  describe CloudLayerio::Options::PreviewOptions do
    it 'serializes with camelCase keys' do
      po = described_class.new(width: 200, height: 150, quality: 80, maintain_aspect_ratio: true)
      h = po.to_h
      expect(h['maintainAspectRatio']).to eq(true)
      expect(h['quality']).to eq(80)
    end
  end

  describe CloudLayerio::Options::WaitForSelectorOptions do
    it 'serializes with nested options hash' do
      wfs = described_class.new(selector: '#content', options: { 'visible' => true, 'timeout' => 5000 })
      h = wfs.to_h
      expect(h['selector']).to eq('#content')
      expect(h['options']).to eq('visible' => true, 'timeout' => 5000)
    end
  end

  describe CloudLayerio::Options::PdfOptions do
    it 'serializes with nested components' do
      margin = CloudLayerio::Options::Margin.new(top: '1in', bottom: '1in')
      pdf = described_class.new(print_background: true, format: 'a4', margin: margin)
      h = pdf.to_h
      expect(h['printBackground']).to eq(true)
      expect(h['format']).to eq('a4')
      expect(h['margin']).to eq('top' => '1in', 'bottom' => '1in')
    end

    it 'handles generate_preview as boolean' do
      pdf = described_class.new(generate_preview: true)
      expect(pdf.to_h['generatePreview']).to eq(true)
    end

    it 'handles generate_preview as PreviewOptions' do
      preview = CloudLayerio::Options::PreviewOptions.new(width: 200, quality: 80)
      pdf = described_class.new(generate_preview: preview)
      expect(pdf.to_h['generatePreview']).to eq('width' => 200, 'quality' => 80)
    end
  end

  describe CloudLayerio::Options::ImageOptions do
    it 'serializes image-specific fields' do
      img = described_class.new(image_type: 'png', quality: 90, trim: true, transparent: true)
      h = img.to_h
      expect(h).to eq('imageType' => 'png', 'quality' => 90, 'trim' => true, 'transparent' => true)
    end
  end

  describe CloudLayerio::Options::PuppeteerOptions do
    it 'serializes preferCSSPageSize correctly' do
      pp = described_class.new(prefer_css_page_size: true)
      expect(pp.to_h['preferCSSPageSize']).to eq(true)
    end

    it 'serializes viewPort (capital P)' do
      vp = CloudLayerio::Options::Viewport.new(width: 800, height: 600)
      pp = described_class.new(view_port: vp)
      expect(pp.to_h['viewPort']).to eq('width' => 800, 'height' => 600)
    end

    context 'with emulate_media_type three-state' do
      it 'omits when NOT_SET (not provided)' do
        pp = described_class.new
        expect(pp.to_h).not_to have_key('emulateMediaType')
      end

      it 'includes nil as JSON null' do
        pp = described_class.new(emulate_media_type: nil)
        expect(pp.to_h).to have_key('emulateMediaType')
        expect(pp.to_h['emulateMediaType']).to be_nil
      end

      it 'includes string value' do
        pp = described_class.new(emulate_media_type: 'screen')
        expect(pp.to_h['emulateMediaType']).to eq('screen')
      end
    end

    it 'handles LayoutDimension (string or numeric) for height/width' do
      pp = described_class.new(height: '100vh', width: 800)
      h = pp.to_h
      expect(h['height']).to eq('100vh')
      expect(h['width']).to eq(800)
    end
  end

  describe CloudLayerio::Options::BaseOptions do
    it 'serializes common fields' do
      bo = described_class.new(name: 'test', timeout: 30_000, async: true, api_ver: 'v2', project_id: 'proj-1')
      h = bo.to_h
      expect(h['name']).to eq('test')
      expect(h['timeout']).to eq(30_000)
      expect(h['async']).to eq(true)
      expect(h['apiVer']).to eq('v2')
      expect(h['projectId']).to eq('proj-1')
    end

    it 'handles storage as boolean' do
      bo = described_class.new(storage: true)
      expect(bo.to_h['storage']).to eq(true)
    end

    it 'handles storage as hash with id' do
      bo = described_class.new(storage: { 'id' => 'store-1' })
      expect(bo.to_h['storage']).to eq('id' => 'store-1')
    end
  end

  describe CloudLayerio::Options::StorageParams do
    it 'serializes storage CRUD params' do
      sp = described_class.new(
        title: 'My S3',
        region: 'us-east-1',
        access_key_id: 'AKIA...',
        secret_access_key: 'secret',
        bucket: 'my-bucket',
        endpoint: 'https://s3.example.com'
      )
      h = sp.to_h
      expect(h['accessKeyId']).to eq('AKIA...')
      expect(h['secretAccessKey']).to eq('secret')
      expect(h['endpoint']).to eq('https://s3.example.com')
    end
  end

  describe CloudLayerio::Options::ListTemplatesOptions do
    it 'serializes query params' do
      lto = described_class.new(type: 'pdf', category: 'invoice', tags: 'business,modern', expand: true)
      h = lto.to_h
      expect(h['type']).to eq('pdf')
      expect(h['tags']).to eq('business,modern')
      expect(h['expand']).to eq(true)
    end
  end

  describe CloudLayerio::Options::WaitForJobOptions do
    it 'has defaults' do
      wfj = described_class.new
      expect(wfj.interval).to eq(5)
      expect(wfj.max_wait).to eq(300)
    end

    it 'rejects interval < 2' do
      expect { described_class.new(interval: 1) }.to raise_error(CloudLayerio::ValidationError)
    end

    it 'accepts custom values' do
      wfj = described_class.new(interval: 10, max_wait: 600)
      expect(wfj.interval).to eq(10)
      expect(wfj.max_wait).to eq(600)
    end
  end

  describe 'OptionBase behavior' do
    it 'rejects unknown keyword arguments' do
      expect { CloudLayerio::Options::Margin.new(unknown: 'value') }
        .to raise_error(ArgumentError, /unknown/)
    end

    it 'returns empty hash when no fields set' do
      margin = CloudLayerio::Options::Margin.new
      expect(margin.to_h).to eq({})
    end
  end
end
