# frozen_string_literal: true

# Smoke tests that hit the live CloudLayer.io API.
# Excluded from default test suite. Run with:
#   CLOUDLAYER_API_KEY=<key> bundle exec rspec --tag smoke
RSpec.describe 'Smoke Tests', :smoke do
  let(:api_key) { ENV.fetch('CLOUDLAYER_API_KEY', nil) }

  before do
    skip 'CLOUDLAYER_API_KEY not set' unless api_key
    WebMock.allow_net_connect!
  end

  after do
    WebMock.disable_net_connect!
  end

  describe 'get_status' do
    it 'returns ok response' do
      client = CloudLayerio::Client.new(api_key: api_key, api_version: :v2)
      resp = client.get_status
      expect(resp.status).to start_with('ok')
    end
  end

  describe 'get_account' do
    it 'returns account info' do
      client = CloudLayerio::Client.new(api_key: api_key, api_version: :v2)
      acct = client.get_account
      expect(acct.email).to be_a(String)
      expect(acct.sub_active).not_to be_nil
    end
  end

  describe 'list_templates' do
    it 'returns templates array' do
      client = CloudLayerio::Client.new(api_key: api_key, api_version: :v2)
      templates = client.list_templates
      expect(templates).to be_an(Array)
      expect(templates.first).to be_a(CloudLayerio::Responses::PublicTemplate) if templates.any?
    end
  end

  describe 'v2 url_to_pdf' do
    it 'returns Job object' do
      client = CloudLayerio::Client.new(api_key: api_key, api_version: :v2)
      result = client.url_to_pdf(url: 'https://example.com', async: true, storage: true)
      expect(result.job?).to be true
      expect(result.job.id).to be_a(String)
    end
  end

  describe 'v2 wait_for_job + download_job_result workflow' do
    it 'converts and downloads a PDF' do
      client = CloudLayerio::Client.new(api_key: api_key, api_version: :v2)
      result = client.url_to_pdf(url: 'https://example.com', async: true, storage: true)
      job = client.wait_for_job(result.job.id, interval: 3, max_wait: 120)
      expect(job.success?).to be true

      data = client.download_job_result(job)
      expect(data).to start_with('%PDF')
    end
  end

  describe 'invalid API key' do
    it 'raises AuthError' do
      client = CloudLayerio::Client.new(api_key: 'invalid-key', api_version: :v2)
      expect { client.get_account }.to raise_error(CloudLayerio::AuthError)
    end
  end
end
