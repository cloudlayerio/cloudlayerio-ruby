# frozen_string_literal: true

module CloudLayerio
  module Http
    # Retry policy with exponential backoff and jitter.
    # Retries on 429 (rate limit) and 500-504 (server errors).
    # Never retries on 400, 401, 403, 404, 422 (client errors).
    class RetryPolicy
      RETRYABLE_STATUSES = [429, 500, 502, 503, 504].freeze
      MAX_BACKOFF_SECONDS = 16

      attr_reader :max_retries

      def initialize(max_retries)
        @max_retries = max_retries
      end

      # Executes the block with retry logic.
      # Yields the current attempt number (0-based).
      def execute
        last_error = nil

        (0..@max_retries).each do |attempt|
          return yield(attempt)
        rescue RateLimitError => e
          last_error = e
          raise unless attempt < @max_retries

          sleep(e.retry_after || backoff_seconds(attempt))
        rescue ApiError => e
          last_error = e
          raise unless should_retry?(attempt, e.status_code)

          sleep(backoff_seconds(attempt))
        end

        raise last_error
      end

      # Calculates backoff delay: min(2^attempt, 16) + jitter [0, 0.5]
      def backoff_seconds(attempt)
        base = [2**attempt, MAX_BACKOFF_SECONDS].min
        base + (rand * 0.5)
      end

      def retryable_status?(status)
        RETRYABLE_STATUSES.include?(status)
      end

      private

      def should_retry?(attempt, status)
        attempt < @max_retries && retryable_status?(status)
      end
    end
  end
end
