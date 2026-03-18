# frozen_string_literal: true

RSpec.describe CloudLayerio::Http::Transport do
  let(:config) do
    c = CloudLayerio::Configuration.new
    c.api_key = 'test-api-key'
    c.api_version = :v2
    c.timeout = 30
    c.max_retries = 0
    c.validate!
    c
  end

  subject(:transport) { described_class.new(config) }

  describe '#post_json' do
    it 'sends POST with JSON body and correct headers' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .with(
          headers: {
            'X-API-Key' => 'test-api-key',
            'Content-Type' => 'application/json',
            'User-Agent' => /cloudlayerio-ruby/
          },
          body: '{"url":"https://example.com","format":"a4"}'
        )
        .to_return(
          status: 200,
          body: '{"id":"job-1","status":"pending"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = transport.post_json('/url/pdf', { 'url' => 'https://example.com', 'format' => 'a4' })
      expect(result[:data]['id']).to eq('job-1')
      expect(result[:status]).to eq(200)
    end

    it 'treats HTTP 202 as success' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(
          status: 202,
          body: '{"id":"job-1","status":"pending"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = transport.post_json('/url/pdf', {})
      expect(result[:status]).to eq(202)
      expect(result[:data]['status']).to eq('pending')
    end

    it 'returns binary response for non-JSON content type' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(
          status: 200,
          body: 'PDF-binary-data',
          headers: {
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename="output.pdf"'
          }
        )

      result = transport.post_json('/url/pdf', {})
      expect(result[:data]).to eq('PDF-binary-data')
      expect(result[:filename]).to eq('output.pdf')
    end

    it 'parses ResponseHeaders from cl-* headers' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(
          status: 200,
          body: '{"id":"job-1"}',
          headers: {
            'Content-Type' => 'application/json',
            'cl-worker-job-id' => 'wj-123',
            'cl-bandwidth' => '2048'
          }
        )

      result = transport.post_json('/url/pdf', {})
      expect(result[:headers].worker_job_id).to eq('wj-123')
      expect(result[:headers].bandwidth).to eq(2048)
    end
  end

  describe '#get' do
    it 'sends GET with query params and API key' do
      stub_request(:get, 'https://api.cloudlayer.io/v2/jobs/job-1')
        .with(headers: { 'X-API-Key' => 'test-api-key' })
        .to_return(
          status: 200,
          body: '{"id":"job-1","status":"success"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = transport.get('/jobs/job-1')
      expect(result[:data]['id']).to eq('job-1')
    end

    it 'appends query parameters to URL' do
      stub_request(:get, 'https://api.cloudlayer.io/v2/assets?limit=10&offset=0')
        .to_return(
          status: 200,
          body: '[]',
          headers: { 'Content-Type' => 'application/json' }
        )

      transport.get('/assets', query_params: { limit: 10, offset: 0 })
    end

    it 'uses absolute_path when specified (bypasses version prefix)' do
      stub_request(:get, 'https://api.cloudlayer.io/v2/templates')
        .to_return(
          status: 200,
          body: '[]',
          headers: { 'Content-Type' => 'application/json' }
        )

      transport.get('/v2/templates', absolute_path: true)
    end
  end

  describe '#delete' do
    it 'sends DELETE request' do
      stub_request(:delete, 'https://api.cloudlayer.io/v2/storage/stor-1')
        .to_return(
          status: 200,
          body: '{"id":"stor-1"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = transport.delete('/storage/stor-1')
      expect(result[:data]['id']).to eq('stor-1')
    end
  end

  describe '#post_multipart' do
    it 'sends multipart form-data' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/docx/pdf')
        .with(headers: { 'Content-Type' => /multipart\/form-data; boundary=/ })
        .to_return(
          status: 200,
          body: '{"id":"job-1"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      parts = [
        { name: 'file', value: 'docx-bytes', filename: 'doc.docx' },
        { name: 'timeout', value: '30000' }
      ]
      result = transport.post_multipart('/docx/pdf', parts)
      expect(result[:data]['id']).to eq('job-1')
    end
  end

  describe '#get_raw' do
    it 'fetches binary without X-API-Key header' do
      stub_request(:get, 'https://cdn.example.com/file.pdf')
        .with { |req| req.headers['X-Api-Key'].nil? }
        .to_return(status: 200, body: 'pdf-bytes')

      result = transport.get_raw('https://cdn.example.com/file.pdf')
      expect(result[:body]).to eq('pdf-bytes')
      expect(result[:status]).to eq(200)
    end

    it 'follows redirects up to 5 hops' do
      stub_request(:get, 'https://cdn.example.com/redirect1')
        .to_return(status: 302, headers: { 'Location' => 'https://cdn.example.com/redirect2' })
      stub_request(:get, 'https://cdn.example.com/redirect2')
        .to_return(status: 200, body: 'final-content')

      result = transport.get_raw('https://cdn.example.com/redirect1')
      expect(result[:body]).to eq('final-content')
    end

    it 'raises NetworkError after too many redirects' do
      (1..6).each do |i|
        stub_request(:get, "https://cdn.example.com/redirect#{i}")
          .to_return(status: 302, headers: { 'Location' => "https://cdn.example.com/redirect#{i + 1}" })
      end

      expect { transport.get_raw('https://cdn.example.com/redirect1') }
        .to raise_error(CloudLayerio::NetworkError, /Too many redirects/)
    end

    it 'raises NetworkError on redirect without Location' do
      stub_request(:get, 'https://cdn.example.com/bad-redirect')
        .to_return(status: 302)

      expect { transport.get_raw('https://cdn.example.com/bad-redirect') }
        .to raise_error(CloudLayerio::NetworkError, /Location/)
    end
  end

  describe 'error mapping' do
    it 'maps 401 to AuthError' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(status: 401, body: '{"message":"Invalid API key"}',
                   headers: { 'Content-Type' => 'application/json' })

      expect { transport.post_json('/url/pdf', {}) }
        .to raise_error(CloudLayerio::AuthError) { |e|
          expect(e.status_code).to eq(401)
          expect(e.message).to eq('Invalid API key')
        }
    end

    it 'maps 403 to AuthError' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(status: 403, body: '{"message":"Forbidden"}',
                   headers: { 'Content-Type' => 'application/json' })

      expect { transport.post_json('/url/pdf', {}) }
        .to raise_error(CloudLayerio::AuthError) { |e|
          expect(e.status_code).to eq(403)
        }
    end

    it 'maps 429 to RateLimitError with retry_after' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(status: 429, body: '{"message":"Rate limited"}',
                   headers: { 'Retry-After' => '60', 'Content-Type' => 'application/json' })

      expect { transport.post_json('/url/pdf', {}) }
        .to raise_error(CloudLayerio::RateLimitError) { |e|
          expect(e.status_code).to eq(429)
          expect(e.retry_after).to eq(60)
        }
    end

    it 'maps 400 to ApiError' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(status: 400, body: '{"message":"Bad request"}',
                   headers: { 'Content-Type' => 'application/json' })

      expect { transport.post_json('/url/pdf', {}) }
        .to raise_error(CloudLayerio::ApiError) { |e|
          expect(e.status_code).to eq(400)
          expect(e.message).to eq('Bad request')
        }
    end

    it 'maps 500 to ApiError' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(status: 500, body: '{"error":"Internal server error"}',
                   headers: { 'Content-Type' => 'application/json' })

      expect { transport.post_json('/url/pdf', {}) }
        .to raise_error(CloudLayerio::ApiError) { |e|
          expect(e.status_code).to eq(500)
          expect(e.message).to eq('Internal server error')
        }
    end

    it 'extracts error from "error" field as fallback' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(status: 400, body: '{"error":"validation failed"}',
                   headers: { 'Content-Type' => 'application/json' })

      expect { transport.post_json('/url/pdf', {}) }
        .to raise_error(CloudLayerio::ApiError, 'validation failed')
    end

    it 'handles non-JSON error bodies' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(status: 502, body: 'Bad Gateway')

      expect { transport.post_json('/url/pdf', {}) }
        .to raise_error(CloudLayerio::ApiError, /502/)
    end

    it 'maps Net::ReadTimeout to TimeoutError' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_timeout

      expect { transport.post_json('/url/pdf', {}) }
        .to raise_error(CloudLayerio::TimeoutError, /timed out/)
    end

    it 'maps SocketError to NetworkError' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_raise(SocketError.new('getaddrinfo: Name or service not known'))

      expect { transport.post_json('/url/pdf', {}) }
        .to raise_error(CloudLayerio::NetworkError, /Connection failed/)
    end

    it 'maps Errno::ECONNREFUSED to NetworkError' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_raise(Errno::ECONNREFUSED)

      expect { transport.post_json('/url/pdf', {}) }
        .to raise_error(CloudLayerio::NetworkError)
    end

    it 'includes path and method in ApiError' do
      stub_request(:get, 'https://api.cloudlayer.io/v2/jobs/job-1')
        .to_return(status: 404, body: '{"message":"Not found"}',
                   headers: { 'Content-Type' => 'application/json' })

      expect { transport.get('/jobs/job-1') }
        .to raise_error(CloudLayerio::ApiError) { |e|
          expect(e.path).to include('/jobs/job-1')
          expect(e.method_name).to eq('GET')
          expect(e.response_body).to include('Not found')
        }
    end
  end

  describe 'retry integration' do
    let(:retry_config) do
      c = CloudLayerio::Configuration.new
      c.api_key = 'test-key'
      c.api_version = :v2
      c.max_retries = 2
      c.validate!
      c
    end

    let(:retry_transport) { described_class.new(retry_config) }

    it 'retries GET on 500 when retryable' do
      stub_request(:get, 'https://api.cloudlayer.io/v2/jobs/job-1')
        .to_return(status: 500, body: '{"error":"temp"}', headers: { 'Content-Type' => 'application/json' })
        .then
        .to_return(status: 200, body: '{"id":"job-1"}', headers: { 'Content-Type' => 'application/json' })

      # Allow sleep to be fast
      allow_any_instance_of(CloudLayerio::Http::RetryPolicy).to receive(:sleep) # rubocop:disable RSpec/AnyInstance

      result = retry_transport.get('/jobs/job-1', retryable: true)
      expect(result[:data]['id']).to eq('job-1')
    end

    it 'does NOT retry POST when retryable is false' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(status: 500, body: '{"error":"fail"}', headers: { 'Content-Type' => 'application/json' })

      expect { retry_transport.post_json('/url/pdf', {}, retryable: false) }
        .to raise_error(CloudLayerio::ApiError)
    end
  end

  describe 'Content-Disposition parsing' do
    it 'parses quoted filename' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(
          status: 200,
          body: 'pdf-data',
          headers: {
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename="report.pdf"'
          }
        )

      result = transport.post_json('/url/pdf', {})
      expect(result[:filename]).to eq('report.pdf')
    end

    it 'parses unquoted filename' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(
          status: 200,
          body: 'pdf-data',
          headers: {
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename=report.pdf'
          }
        )

      result = transport.post_json('/url/pdf', {})
      expect(result[:filename]).to eq('report.pdf')
    end

    it 'returns nil when no Content-Disposition' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/url/pdf')
        .to_return(status: 200, body: 'pdf-data', headers: { 'Content-Type' => 'application/pdf' })

      result = transport.post_json('/url/pdf', {})
      expect(result[:filename]).to be_nil
    end
  end
end
