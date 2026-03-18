# frozen_string_literal: true

RSpec.describe 'CloudLayerio Error Hierarchy' do
  describe CloudLayerio::Error do
    it 'inherits from StandardError' do
      expect(described_class.ancestors).to include(StandardError)
    end
  end

  describe CloudLayerio::ConfigError do
    it 'inherits from Error' do
      expect(described_class.ancestors).to include(CloudLayerio::Error)
    end
  end

  describe CloudLayerio::ValidationError do
    it 'inherits from Error' do
      expect(described_class.ancestors).to include(CloudLayerio::Error)
    end
  end

  describe CloudLayerio::NetworkError do
    it 'inherits from Error' do
      expect(described_class.ancestors).to include(CloudLayerio::Error)
    end
  end

  describe CloudLayerio::TimeoutError do
    it 'inherits from Error' do
      expect(described_class.ancestors).to include(CloudLayerio::Error)
    end
  end

  describe CloudLayerio::ApiError do
    it 'inherits from Error' do
      expect(described_class.ancestors).to include(CloudLayerio::Error)
    end

    it 'carries HTTP details' do
      error = described_class.new(
        'Not Found',
        status_code: 404,
        status_text: 'Not Found',
        path: '/v2/jobs/abc',
        method_name: 'GET',
        response_body: '{"error":"not found"}'
      )
      expect(error.status_code).to eq(404)
      expect(error.status_text).to eq('Not Found')
      expect(error.path).to eq('/v2/jobs/abc')
      expect(error.method_name).to eq('GET')
      expect(error.response_body).to eq('{"error":"not found"}')
      expect(error.message).to eq('Not Found')
    end

    it 'builds a default message from HTTP details' do
      error = described_class.new(status_code: 500, status_text: 'Internal Server Error', path: '/v2/convert')
      expect(error.message).to include('500')
      expect(error.message).to include('Internal Server Error')
    end
  end

  describe CloudLayerio::AuthError do
    it 'inherits from ApiError' do
      expect(described_class.ancestors).to include(CloudLayerio::ApiError)
    end

    it 'is catchable as ApiError' do
      expect {
        raise described_class.new('Unauthorized', status_code: 401)
      }.to raise_error(CloudLayerio::ApiError)
    end
  end

  describe CloudLayerio::RateLimitError do
    it 'inherits from ApiError' do
      expect(described_class.ancestors).to include(CloudLayerio::ApiError)
    end

    it 'includes retry_after' do
      error = described_class.new('Rate limited', status_code: 429, retry_after: 60)
      expect(error.retry_after).to eq(60)
      expect(error.status_code).to eq(429)
    end

    it 'allows nil retry_after' do
      error = described_class.new('Rate limited', status_code: 429)
      expect(error.retry_after).to be_nil
    end
  end
end
