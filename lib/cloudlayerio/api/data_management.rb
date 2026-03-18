# frozen_string_literal: true

module CloudLayerio
  module Api
    # Data management API methods: jobs, assets, storage, account, templates,
    # plus utility methods wait_for_job and download_job_result.
    # Method names match the API convention across all CloudLayer SDKs.
    module DataManagement
      # --- Jobs ---

      # Returns up to 10 most recent jobs (server-side limit).
      # @return [Array<Responses::Job>]
      def list_jobs
        result = transport.get('/jobs', retryable: true)
        result[:data].map { |h| Responses::Job.from_hash(h) }
      end

      # Returns a single job by ID.
      # @param job_id [String] job identifier
      # @return [Responses::Job]
      # @raise [ValidationError] if job_id is empty
      def get_job(job_id)
        validate_id!(job_id, 'job_id')
        result = transport.get("/jobs/#{job_id}", retryable: true)
        Responses::Job.from_hash(result[:data])
      end

      # --- Assets ---

      # Returns up to 10 most recent assets.
      def list_assets
        result = transport.get('/assets', retryable: true)
        result[:data].map { |h| Responses::Asset.from_hash(h) }
      end

      # Returns a single asset by ID.
      def get_asset(asset_id)
        validate_id!(asset_id, 'asset_id')
        result = transport.get("/assets/#{asset_id}", retryable: true)
        Responses::Asset.from_hash(result[:data])
      end

      # --- Storage ---

      # Returns all storage configurations (id, title only).
      def list_storage
        result = transport.get('/storage', retryable: true)
        result[:data].map { |h| Responses::StorageListItem.from_hash(h) }
      end

      # Returns a single storage configuration.
      def get_storage(storage_id)
        validate_id!(storage_id, 'storage_id')
        result = transport.get("/storage/#{storage_id}", retryable: true)
        Responses::StorageDetail.from_hash(result[:data])
      end

      # Creates a new storage configuration.
      # Raises ApiError if plan doesn't support storage.
      def add_storage(**params)
        opts = Options::StorageParams.new(**params)
        result = transport.post_json('/storage', opts.to_h, retryable: false)
        data = result[:data]
        check_storage_allowed!(data)
        Responses::StorageCreateResponse.from_hash(data)
      end

      # Deletes a storage configuration. Returns true on success.
      def delete_storage(storage_id)
        validate_id!(storage_id, 'storage_id')
        transport.delete("/storage/#{storage_id}", retryable: false)
        true
      end

      # --- Account ---

      # Returns account information.
      def get_account
        result = transport.get('/account', retryable: true)
        Responses::AccountInfo.from_hash(result[:data])
      end

      # Returns API status. Note: status value is "ok " with trailing space.
      def get_status
        result = transport.get('/getStatus', retryable: true)
        Responses::StatusResponse.from_hash(result[:data])
      end

      # --- Templates ---

      # Lists public templates. Always uses /v2/ regardless of client api_version.
      def list_templates(**options)
        query = build_template_query(options)
        result = transport.get('/v2/templates', query_params: query, retryable: true, absolute_path: true)
        result[:data].map { |h| Responses::PublicTemplate.from_hash(h) }
      end

      # Returns a single public template. Always uses /v2/ regardless of client api_version.
      def get_template(template_id)
        validate_id!(template_id, 'template_id')
        result = transport.get("/v2/template/#{template_id}", retryable: true, absolute_path: true)
        Responses::PublicTemplate.from_hash(result[:data])
      end

      # --- Utility Methods ---

      # Polls get_job until status is "success" or "error".
      #
      # @param job_id [String] job identifier to poll
      # @param interval [Numeric] seconds between polls (default 5, minimum 2)
      # @param max_wait [Numeric] maximum total seconds to wait (default 300)
      # @return [Responses::Job] the completed job
      # @raise [ValidationError] if interval < 2 or job_id empty
      # @raise [TimeoutError] if max_wait exceeded
      # @raise [ApiError] if job status is "error"
      def wait_for_job(job_id, interval: 5, max_wait: 300)
        raise ValidationError, 'interval must be >= 2 seconds' if interval < 2

        validate_id!(job_id, 'job_id')
        deadline = Time.now + max_wait

        loop do
          job = get_job(job_id)
          return job if job.success?

          if job.error?
            raise ApiError.new("Job #{job_id} failed: #{job.error}",
                               status_code: nil, path: "/jobs/#{job_id}")
          end

          raise TimeoutError, "Job #{job_id} did not complete within #{max_wait} seconds" if Time.now >= deadline

          sleep(interval)
        end
      end

      # Downloads the binary result of a completed job.
      #
      # @param job [Responses::Job, Hash] job with asset_url
      # @return [String] raw binary data (Encoding::BINARY)
      # @raise [ValidationError] if job.asset_url is nil/empty
      def download_job_result(job)
        asset_url = job.respond_to?(:asset_url) ? job.asset_url : job[:asset_url]
        raise ValidationError, 'job.asset_url is required for download' if asset_url.nil? || asset_url.to_s.empty?

        result = transport.get_raw(asset_url)
        result[:body]
      end

      private

      def build_template_query(options)
        query = options.slice(:type, :category, :tags)
        query[:expand] = options[:expand] if options.key?(:expand)
        query.compact
      end

      def validate_id!(value, name)
        raise ValidationError, "#{name} must be a non-empty string" if value.nil? || value.to_s.strip.empty?
      end

      def check_storage_allowed!(data)
        return unless data.is_a?(Hash) && data.key?('allowed') && data['allowed'] == false

        reason = data['reason'] || 'Storage not allowed on this plan'
        raise ApiError.new(reason, status_code: data['statusCode'])
      end
    end
  end
end
