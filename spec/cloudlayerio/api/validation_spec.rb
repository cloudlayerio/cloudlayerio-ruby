# frozen_string_literal: true

RSpec.describe CloudLayerio::Api::Validation do
  describe '.validate_url_options' do
    it 'passes with valid url' do
      expect { described_class.validate_url_options(url: 'https://example.com') }.not_to raise_error
    end

    it 'passes with valid batch' do
      expect {
        described_class.validate_url_options(batch: { urls: ['https://a.com', 'https://b.com'] })
      }.not_to raise_error
    end

    it 'fails when neither url nor batch provided' do
      expect { described_class.validate_url_options({}) }
        .to raise_error(CloudLayerio::ValidationError, /url or batch/)
    end

    it 'fails when both url and batch provided' do
      expect {
        described_class.validate_url_options(url: 'https://a.com', batch: { urls: ['https://b.com'] })
      }.to raise_error(CloudLayerio::ValidationError, /mutually exclusive/)
    end

    it 'fails when batch has > 20 URLs' do
      urls = (1..21).map { |i| "https://#{i}.com" }
      expect {
        described_class.validate_url_options(batch: { urls: urls })
      }.to raise_error(CloudLayerio::ValidationError, /max 20/)
    end

    it 'fails when batch urls is empty' do
      expect {
        described_class.validate_url_options(batch: { urls: [] })
      }.to raise_error(CloudLayerio::ValidationError, /url or batch/)
    end
  end

  describe '.validate_html_options' do
    it 'passes with html present' do
      expect { described_class.validate_html_options(html: 'PGgxPg==') }.not_to raise_error
    end

    it 'fails when html is nil' do
      expect { described_class.validate_html_options({}) }
        .to raise_error(CloudLayerio::ValidationError, /html is required/)
    end

    it 'fails when html is empty' do
      expect { described_class.validate_html_options(html: '') }
        .to raise_error(CloudLayerio::ValidationError, /html is required/)
    end
  end

  describe '.validate_template_options' do
    it 'passes with template_id' do
      expect { described_class.validate_template_options(template_id: 'tmpl-1') }.not_to raise_error
    end

    it 'passes with template' do
      expect { described_class.validate_template_options(template: 'PGgx...') }.not_to raise_error
    end

    it 'fails when neither provided' do
      expect { described_class.validate_template_options({}) }
        .to raise_error(CloudLayerio::ValidationError, /template_id or template is required/)
    end

    it 'fails when both provided' do
      expect {
        described_class.validate_template_options(template_id: 'tmpl-1', template: 'PGgx...')
      }.to raise_error(CloudLayerio::ValidationError, /mutually exclusive/)
    end
  end

  describe '.validate_file_options' do
    it 'passes with file present' do
      expect { described_class.validate_file_options(file: '/path/to/doc.docx') }.not_to raise_error
    end

    it 'fails when file is nil' do
      expect { described_class.validate_file_options({}) }
        .to raise_error(CloudLayerio::ValidationError, /file is required/)
    end
  end

  describe '.validate_image_options' do
    it 'passes when quality is nil' do
      expect { described_class.validate_image_options({}) }.not_to raise_error
    end

    it 'passes when quality is 0-100' do
      expect { described_class.validate_image_options(quality: 80) }.not_to raise_error
    end

    it 'fails when quality < 0' do
      expect { described_class.validate_image_options(quality: -1) }
        .to raise_error(CloudLayerio::ValidationError, /quality/)
    end

    it 'fails when quality > 100' do
      expect { described_class.validate_image_options(quality: 101) }
        .to raise_error(CloudLayerio::ValidationError, /quality/)
    end
  end

  describe 'base option validation' do
    it 'fails when timeout < 1000' do
      expect { described_class.validate_base_options(timeout: 500) }
        .to raise_error(CloudLayerio::ValidationError, /timeout/)
    end

    it 'passes when timeout >= 1000' do
      expect { described_class.validate_base_options(timeout: 1000) }.not_to raise_error
    end

    it 'fails when async true without storage' do
      expect { described_class.validate_base_options(async: true) }
        .to raise_error(CloudLayerio::ValidationError, /async.*storage/)
    end

    it 'passes when async true with storage' do
      expect { described_class.validate_base_options(async: true, storage: true) }.not_to raise_error
    end

    it 'fails when webhook is not HTTPS' do
      expect { described_class.validate_base_options(webhook: 'http://example.com') }
        .to raise_error(CloudLayerio::ValidationError, /HTTPS/)
    end

    it 'fails when storage hash has empty id' do
      expect { described_class.validate_base_options(storage: { id: '' }) }
        .to raise_error(CloudLayerio::ValidationError, /storage.id/)
    end

    it 'fails when authentication has empty username' do
      expect {
        described_class.validate_url_options(url: 'https://a.com', authentication: { username: '', password: 'pass' })
      }.to raise_error(CloudLayerio::ValidationError, /authentication/)
    end

    it 'fails when cookie has empty name' do
      expect {
        described_class.validate_url_options(url: 'https://a.com', cookies: [{ name: '', value: 'v' }])
      }.to raise_error(CloudLayerio::ValidationError, /cookie/)
    end
  end
end
