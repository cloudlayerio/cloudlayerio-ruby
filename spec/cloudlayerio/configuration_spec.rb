# frozen_string_literal: true

RSpec.describe CloudLayerio::Configuration do
  subject(:config) { described_class.new }

  describe 'defaults' do
    it 'has correct default values' do
      expect(config.base_url).to eq('https://api.cloudlayer.io')
      expect(config.timeout).to eq(30)
      expect(config.max_retries).to eq(2)
      expect(config.user_agent).to start_with('cloudlayerio-ruby/')
      expect(config.headers).to eq({})
    end
  end

  describe '#validate!' do
    it 'raises ConfigError when api_key is nil' do
      config.api_version = :v2
      expect { config.validate! }.to raise_error(CloudLayerio::ConfigError, /api_key/)
    end

    it 'raises ConfigError when api_key is empty' do
      config.api_key = '  '
      config.api_version = :v2
      expect { config.validate! }.to raise_error(CloudLayerio::ConfigError, /api_key/)
    end

    it 'raises ConfigError when api_version is invalid' do
      config.api_key = 'test'
      config.api_version = :v3
      expect { config.validate! }.to raise_error(CloudLayerio::ConfigError, /api_version/)
    end

    it 'accepts symbol api_version' do
      config.api_key = 'test'
      config.api_version = :v1
      expect { config.validate! }.not_to raise_error
    end

    it 'accepts string api_version' do
      config.api_key = 'test'
      config.api_version = 'v2'
      expect { config.validate! }.not_to raise_error
    end

    it 'raises ConfigError when base_url is invalid' do
      config.api_key = 'test'
      config.api_version = :v2
      config.base_url = 'not-a-url'
      expect { config.validate! }.to raise_error(CloudLayerio::ConfigError, /base_url/)
    end

    it 'raises ConfigError when timeout is not positive' do
      config.api_key = 'test'
      config.api_version = :v2
      config.timeout = 0
      expect { config.validate! }.to raise_error(CloudLayerio::ConfigError, /timeout/)
    end

    it 'clamps max_retries to 0..5' do
      config.api_key = 'test'
      config.api_version = :v2
      config.max_retries = 10
      config.validate!
      expect(config.max_retries).to eq(5)
    end

    it 'clamps negative max_retries to 0' do
      config.api_key = 'test'
      config.api_version = :v2
      config.max_retries = -1
      config.validate!
      expect(config.max_retries).to eq(0)
    end
  end

  describe '#resolved_api_version' do
    it 'resolves :v1 to "v1"' do
      config.api_version = :v1
      expect(config.resolved_api_version).to eq('v1')
    end

    it 'resolves :v2 to "v2"' do
      config.api_version = :v2
      expect(config.resolved_api_version).to eq('v2')
    end

    it 'resolves "v2" to "v2"' do
      config.api_version = 'v2'
      expect(config.resolved_api_version).to eq('v2')
    end
  end
end
