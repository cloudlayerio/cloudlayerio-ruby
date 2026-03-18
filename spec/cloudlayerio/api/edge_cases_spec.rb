# frozen_string_literal: true

# Edge-case tests for data management API behaviors documented in the plan.
RSpec.describe 'Data Management Edge Cases' do
  let(:client) { CloudLayerio::Client.new(api_key: 'test-key', api_version: :v2) }

  describe 'get_storage not found' do
    it 'handles HTTP 400 (not 404) with "No storage document found."' do
      stub_request(:get, 'https://api.cloudlayer.io/v2/storage/nonexistent')
        .to_return(status: 400, body: '{"message":"No storage document found."}',
                   headers: { 'Content-Type' => 'application/json' })

      expect { client.get_storage('nonexistent') }
        .to raise_error(CloudLayerio::ApiError) { |e|
          expect(e.status_code).to eq(400)
          expect(e.message).to eq('No storage document found.')
        }
    end
  end

  describe 'delete_storage not found' do
    it 'handles HTTP 400 with "No storage document found."' do
      stub_request(:delete, 'https://api.cloudlayer.io/v2/storage/nonexistent')
        .to_return(status: 400, body: '{"message":"No storage document found."}',
                   headers: { 'Content-Type' => 'application/json' })

      expect { client.delete_storage('nonexistent') }
        .to raise_error(CloudLayerio::ApiError, 'No storage document found.')
    end
  end

  describe 'add_storage duplicate title' do
    it 'handles HTTP 400 with duplicate title message' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/storage')
        .to_return(status: 400,
                   body: '{"message":"A storage document with this title already exists. Title must be unique."}',
                   headers: { 'Content-Type' => 'application/json' })

      expect {
        client.add_storage(title: 'Dup', region: 'us-east-1', access_key_id: 'a',
                           secret_access_key: 's', bucket: 'b')
      }.to raise_error(CloudLayerio::ApiError, /Title must be unique/)
    end
  end

  describe 'add_storage not allowed (fixture)' do
    it 'raises ApiError from storage_not_allowed fixture' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/storage')
        .to_return(status: 200, body: fixture('storage_not_allowed'),
                   headers: { 'Content-Type' => 'application/json' })

      expect {
        client.add_storage(title: 'X', region: 'r', access_key_id: 'a',
                           secret_access_key: 's', bucket: 'b')
      }.to raise_error(CloudLayerio::ApiError, /does not support/)
    end
  end

  describe 'viewPort field name' do
    it 'serializes as viewPort (capital P) in request body' do
      stub = stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(status: 200, body: '{"id":"j1","status":"pending"}',
                   headers: { 'Content-Type' => 'application/json' })

      vp = CloudLayerio::Options::Viewport.new(width: 1920, height: 1080)
      client.url_to_pdf(url: 'https://example.com', view_port: vp)

      expect(stub.with { |req|
        body = JSON.parse(req.body)
        body.key?('viewPort') && !body.key?('viewport') && !body.key?('view_port')
      }).to have_been_requested
    end
  end

  describe 'preferCSSPageSize field name' do
    it 'serializes as preferCSSPageSize (capital CSS) in request body' do
      stub = stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(status: 200, body: '{"id":"j1","status":"pending"}',
                   headers: { 'Content-Type' => 'application/json' })

      client.url_to_pdf(url: 'https://example.com', prefer_css_page_size: true)

      expect(stub.with { |req|
        body = JSON.parse(req.body)
        body['preferCSSPageSize'] == true && !body.key?('preferCssPageSize')
      }).to have_been_requested
    end
  end

  describe 'error fixture responses' do
    it 'maps 401 fixture to AuthError' do
      stub_request(:get, 'https://api.cloudlayer.io/v2/account')
        .to_return(status: 401, body: fixture('error_responses/401'),
                   headers: { 'Content-Type' => 'application/json' })

      expect { client.get_account }.to raise_error(CloudLayerio::AuthError, 'Invalid API key')
    end

    it 'maps 429 fixture to RateLimitError' do
      stub_request(:get, 'https://api.cloudlayer.io/v2/account')
        .to_return(status: 429, body: fixture('error_responses/429'),
                   headers: { 'Content-Type' => 'application/json' })

      expect { client.get_account }.to raise_error(CloudLayerio::RateLimitError, 'Rate limit exceeded')
    end

    it 'maps 500 fixture to ApiError using "error" field' do
      stub_request(:get, 'https://api.cloudlayer.io/v2/account')
        .to_return(status: 500, body: fixture('error_responses/500'),
                   headers: { 'Content-Type' => 'application/json' })

      expect { client.get_account }.to raise_error(CloudLayerio::ApiError, 'Internal server error')
    end
  end
end
