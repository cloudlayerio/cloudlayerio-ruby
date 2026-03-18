# frozen_string_literal: true

RSpec.describe CloudLayerio::Client do
  describe 'initialization' do
    it 'creates client with keyword arguments' do
      client = described_class.new(api_key: 'test-key', api_version: :v2)
      expect(client.config.api_key).to eq('test-key')
      expect(client.config.resolved_api_version).to eq('v2')
    end

    it 'creates client with block configuration' do
      client = described_class.new do |c|
        c.api_key = 'block-key'
        c.api_version = :v1
      end
      expect(client.config.api_key).to eq('block-key')
      expect(client.config.resolved_api_version).to eq('v1')
    end

    it 'block overrides keyword arguments' do
      client = described_class.new(api_key: 'kwarg-key', api_version: :v2) do |c|
        c.api_key = 'block-key'
      end
      expect(client.config.api_key).to eq('block-key')
    end

    it 'freezes configuration after creation' do
      client = described_class.new(api_key: 'test', api_version: :v2)
      expect(client.config).to be_frozen
    end

    it 'raises ConfigError without api_key' do
      expect { described_class.new(api_version: :v2) }
        .to raise_error(CloudLayerio::ConfigError, /api_key/)
    end

    it 'raises ConfigError without api_version' do
      expect { described_class.new(api_key: 'test') }
        .to raise_error(CloudLayerio::ConfigError, /api_version/)
    end

    it 'accepts custom base_url, timeout, max_retries' do
      client = described_class.new(
        api_key: 'test',
        api_version: :v2,
        base_url: 'https://custom.api.com',
        timeout: 60,
        max_retries: 3
      )
      expect(client.config.base_url).to eq('https://custom.api.com')
      expect(client.config.timeout).to eq(60)
      expect(client.config.max_retries).to eq(3)
    end

    it 'accepts custom headers' do
      client = described_class.new(
        api_key: 'test',
        api_version: :v2,
        headers: { 'X-Custom' => 'value' }
      )
      expect(client.config.headers).to eq('X-Custom' => 'value')
    end
  end
end
