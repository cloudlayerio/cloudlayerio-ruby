# frozen_string_literal: true

RSpec.describe CloudLayerio::Http::RetryPolicy do
  describe '#execute' do
    it 'returns the block result on success' do
      policy = described_class.new(2)
      result = policy.execute { 'success' }
      expect(result).to eq('success')
    end

    it 'retries on RateLimitError up to max_retries' do
      policy = described_class.new(2)
      allow(policy).to receive(:sleep)

      attempts = 0
      result = policy.execute do
        attempts += 1
        raise CloudLayerio::RateLimitError.new('rate limited', status_code: 429) if attempts < 3

        'success'
      end

      expect(result).to eq('success')
      expect(attempts).to eq(3)
    end

    it 'retries on 500 ApiError' do
      policy = described_class.new(1)
      allow(policy).to receive(:sleep)

      attempts = 0
      result = policy.execute do
        attempts += 1
        raise CloudLayerio::ApiError.new('server error', status_code: 500) if attempts < 2

        'ok'
      end

      expect(result).to eq('ok')
      expect(attempts).to eq(2)
    end

    it 'retries on 502, 503, 504' do
      [502, 503, 504].each do |code|
        policy = described_class.new(1)
        allow(policy).to receive(:sleep)

        attempts = 0
        policy.execute do
          attempts += 1
          raise CloudLayerio::ApiError.new('error', status_code: code) if attempts < 2

          'ok'
        end
        expect(attempts).to eq(2)
      end
    end

    it 'does NOT retry on 400' do
      policy = described_class.new(2)
      expect {
        policy.execute { raise CloudLayerio::ApiError.new('bad request', status_code: 400) }
      }.to raise_error(CloudLayerio::ApiError)
    end

    it 'does NOT retry on 401' do
      policy = described_class.new(2)
      expect {
        policy.execute { raise CloudLayerio::AuthError.new('unauthorized', status_code: 401) }
      }.to raise_error(CloudLayerio::AuthError)
    end

    it 'does NOT retry on 403' do
      policy = described_class.new(2)
      expect {
        policy.execute { raise CloudLayerio::AuthError.new('forbidden', status_code: 403) }
      }.to raise_error(CloudLayerio::AuthError)
    end

    it 'does NOT retry on 404' do
      policy = described_class.new(2)
      expect {
        policy.execute { raise CloudLayerio::ApiError.new('not found', status_code: 404) }
      }.to raise_error(CloudLayerio::ApiError)
    end

    it 'raises last error after max retries exhausted' do
      policy = described_class.new(2)
      allow(policy).to receive(:sleep)

      expect {
        policy.execute { raise CloudLayerio::ApiError.new('server error', status_code: 500) }
      }.to raise_error(CloudLayerio::ApiError, 'server error')
    end

    it 'uses retry_after from RateLimitError when available' do
      policy = described_class.new(1)
      allow(policy).to receive(:sleep)

      attempts = 0
      policy.execute do
        attempts += 1
        raise CloudLayerio::RateLimitError.new('rate limited', status_code: 429, retry_after: 10) if attempts < 2

        'ok'
      end

      expect(policy).to have_received(:sleep).with(10)
    end

    it 'uses backoff when retry_after is nil' do
      policy = described_class.new(1)
      allow(policy).to receive(:sleep)
      allow(policy).to receive(:backoff_seconds).with(0).and_return(1.25)

      attempts = 0
      policy.execute do
        attempts += 1
        raise CloudLayerio::RateLimitError.new('rate limited', status_code: 429) if attempts < 2

        'ok'
      end

      expect(policy).to have_received(:sleep).with(1.25)
    end

    it 'does not swallow Interrupt (SIGINT)' do
      policy = described_class.new(2)
      expect {
        policy.execute { raise Interrupt }
      }.to raise_error(Interrupt)
    end
  end

  describe '#backoff_seconds' do
    subject(:policy) { described_class.new(3) }

    it 'increases exponentially' do
      allow(policy).to receive(:rand).and_return(0)
      expect(policy.backoff_seconds(0)).to eq(1.0)
      expect(policy.backoff_seconds(1)).to eq(2.0)
      expect(policy.backoff_seconds(2)).to eq(4.0)
      expect(policy.backoff_seconds(3)).to eq(8.0)
      expect(policy.backoff_seconds(4)).to eq(16.0)
    end

    it 'caps at 16 seconds' do
      allow(policy).to receive(:rand).and_return(0)
      expect(policy.backoff_seconds(5)).to eq(16.0)
      expect(policy.backoff_seconds(10)).to eq(16.0)
    end

    it 'adds jitter between 0 and 0.5 seconds' do
      allow(policy).to receive(:rand).and_return(0.5)
      expect(policy.backoff_seconds(0)).to eq(1.25)
    end
  end
end
