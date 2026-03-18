# frozen_string_literal: true

RSpec.describe 'CloudLayerio Responses' do
  describe CloudLayerio::Responses::Job do
    let(:job_hash) do
      {
        'id' => 'job-123',
        'uid' => 'user-1',
        'name' => 'test-doc',
        'type' => 'html-pdf',
        'status' => 'success',
        'timestamp' => 1_710_000_000_000,
        'workerName' => 'worker-1',
        'processTime' => 1234,
        'apiKeyUsed' => 'key-xxx',
        'processTimeCost' => 0.05,
        'apiCreditCost' => 1.0,
        'bandwidthCost' => 0.02,
        'totalCost' => 1.07,
        'size' => 50_000,
        'params' => { 'format' => 'a4' },
        'assetUrl' => 'https://cdn.example.com/file.pdf',
        'previewUrl' => 'https://cdn.example.com/preview.png',
        'self' => 'https://api.cloudlayer.io/v2/jobs/job-123',
        'assetId' => 'asset-456',
        'projectId' => 'proj-789'
      }
    end

    it 'deserializes all fields from camelCase hash' do
      job = described_class.from_hash(job_hash)
      expect(job.id).to eq('job-123')
      expect(job.uid).to eq('user-1')
      expect(job.name).to eq('test-doc')
      expect(job.type).to eq('html-pdf')
      expect(job.status).to eq('success')
      expect(job.worker_name).to eq('worker-1')
      expect(job.process_time).to eq(1234)
      expect(job.api_key_used).to eq('key-xxx')
      expect(job.process_time_cost).to eq(0.05)
      expect(job.api_credit_cost).to eq(1.0)
      expect(job.bandwidth_cost).to eq(0.02)
      expect(job.total_cost).to eq(1.07)
      expect(job.size).to eq(50_000)
      expect(job.params).to eq('format' => 'a4')
      expect(job.asset_url).to eq('https://cdn.example.com/file.pdf')
      expect(job.preview_url).to eq('https://cdn.example.com/preview.png')
      expect(job.self_url).to eq('https://api.cloudlayer.io/v2/jobs/job-123')
      expect(job.asset_id).to eq('asset-456')
      expect(job.project_id).to eq('proj-789')
    end

    it 'returns timestamp_ms for numeric milliseconds' do
      job = described_class.from_hash('id' => '1', 'status' => 'success', 'timestamp' => 1_710_000_000_000)
      expect(job.timestamp_ms).to eq(1_710_000_000_000)
    end

    it 'returns timestamp_ms for Firestore _seconds/_nanoseconds format' do
      job = described_class.from_hash(
        'id' => '1', 'status' => 'pending',
        'timestamp' => { '_seconds' => 1_710_000, '_nanoseconds' => 500_000_000 }
      )
      expect(job.timestamp_ms).to eq(1_710_000_500)
    end

    it 'returns nil timestamp_ms for nil timestamp' do
      job = described_class.from_hash('id' => '1', 'status' => 'pending')
      expect(job.timestamp_ms).to be_nil
    end

    it 'provides status predicate methods' do
      success = described_class.from_hash('id' => '1', 'status' => 'success')
      expect(success.success?).to be true
      expect(success.pending?).to be false
      expect(success.error?).to be false

      pending_job = described_class.from_hash('id' => '2', 'status' => 'pending')
      expect(pending_job.pending?).to be true

      errored = described_class.from_hash('id' => '3', 'status' => 'error', 'error' => 'timeout')
      expect(errored.error?).to be true
      expect(errored.error).to eq('timeout')
    end

    it 'ignores unknown fields' do
      job = described_class.from_hash('id' => '1', 'status' => 'success', 'unknownField' => 'ignored')
      expect(job.id).to eq('1')
    end
  end

  describe CloudLayerio::Responses::Asset do
    let(:asset_hash) do
      {
        'uid' => nil,
        'id' => 'asset-1',
        'fileId' => nil,
        'previewFileId' => nil,
        'type' => 'pdf',
        'ext' => '.pdf',
        'previewExt' => '.png',
        'url' => 'https://cdn.example.com/asset.pdf',
        'previewUrl' => 'https://cdn.example.com/preview.png',
        'size' => 25_000,
        'timestamp' => 1_710_000_000_000,
        'projectId' => 'proj-1',
        'jobId' => 'job-1',
        'name' => 'my-doc'
      }
    end

    it 'deserializes from camelCase hash' do
      asset = described_class.from_hash(asset_hash)
      expect(asset.id).to eq('asset-1')
      expect(asset.file_id).to be_nil
      expect(asset.preview_ext).to eq('.png')
      expect(asset.url).to eq('https://cdn.example.com/asset.pdf')
      expect(asset.project_id).to eq('proj-1')
      expect(asset.job_id).to eq('job-1')
    end

    it 'returns timestamp_ms' do
      asset = described_class.from_hash(asset_hash)
      expect(asset.timestamp_ms).to eq(1_710_000_000_000)
    end
  end

  describe CloudLayerio::Responses::AccountInfo do
    let(:account_hash) do
      {
        'email' => 'user@example.com',
        'callsLimit' => 1000,
        'calls' => 42,
        'storageUsed' => 500_000,
        'storageLimit' => 10_000_000,
        'subscription' => 'price_xxx',
        'bytesTotal' => 1_000_000,
        'bytesLimit' => 50_000_000,
        'computeTimeTotal' => 30_000,
        'computeTimeLimit' => -1,
        'subType' => 'usage',
        'uid' => 'uid-123',
        'credit' => 25.50,
        'subActive' => true,
        'customField' => 'extra-value'
      }
    end

    it 'deserializes known fields' do
      acct = described_class.from_hash(account_hash)
      expect(acct.email).to eq('user@example.com')
      expect(acct.calls_limit).to eq(1000)
      expect(acct.calls).to eq(42)
      expect(acct.storage_used).to eq(500_000)
      expect(acct.sub_type).to eq('usage')
      expect(acct.uid).to eq('uid-123')
      expect(acct.credit).to eq(25.50)
      expect(acct.sub_active).to eq(true)
    end

    it 'stores unknown fields in extra' do
      acct = described_class.from_hash(account_hash)
      expect(acct.extra[:custom_field]).to eq('extra-value')
    end

    it 'supports [] access for known and extra fields' do
      acct = described_class.from_hash(account_hash)
      expect(acct[:email]).to eq('user@example.com')
      expect(acct[:custom_field]).to eq('extra-value')
    end
  end

  describe CloudLayerio::Responses::StorageListItem do
    it 'deserializes from hash' do
      item = described_class.from_hash('id' => 'stor-1', 'title' => 'My S3')
      expect(item.id).to eq('stor-1')
      expect(item.title).to eq('My S3')
    end
  end

  describe CloudLayerio::Responses::StorageDetail do
    it 'deserializes from hash' do
      detail = described_class.from_hash('id' => 'stor-1', 'title' => 'My S3')
      expect(detail.id).to eq('stor-1')
      expect(detail.title).to eq('My S3')
    end
  end

  describe CloudLayerio::Responses::StorageCreateResponse do
    it 'deserializes from hash' do
      resp = described_class.from_hash('id' => 'stor-new', 'title' => 'New Storage')
      expect(resp.id).to eq('stor-new')
      expect(resp.title).to eq('New Storage')
    end
  end

  describe CloudLayerio::Responses::StorageNotAllowedResponse do
    it 'deserializes from hash' do
      resp = described_class.from_hash(
        'allowed' => false,
        'reason' => 'Plan does not support storage',
        'statusCode' => 200
      )
      expect(resp.allowed).to eq(false)
      expect(resp.reason).to eq('Plan does not support storage')
      expect(resp.status_code).to eq(200)
    end
  end

  describe CloudLayerio::Responses::StatusResponse do
    it 'preserves exact status string including trailing space' do
      resp = described_class.from_hash('status' => 'ok ')
      expect(resp.status).to eq('ok ')
    end
  end

  describe CloudLayerio::Responses::PublicTemplate do
    let(:template_hash) do
      {
        'id' => 'tmpl-1',
        'templateId' => 'invoice-basic',
        'title' => 'Basic Invoice',
        'shortDescription' => 'A simple invoice template',
        'searchKeywords' => %w[invoice billing],
        'tags' => %w[business finance],
        'category' => 'invoice',
        'type' => 'pdf',
        'previewUrl' => 'https://cdn.example.com/preview.png',
        'exampleAssetUrl' => 'https://cdn.example.com/example.pdf',
        'highlights' => ['Clean design', 'Customizable'],
        'timestamp' => { '_seconds' => 1_710_000, '_nanoseconds' => 0 },
        'projectId' => 'proj-1',
        'sampleData' => { 'company' => 'Acme' },
        'authorName' => 'CloudLayer',
        'unknownFutureField' => 'stored in extra'
      }
    end

    it 'deserializes known fields' do
      tmpl = described_class.from_hash(template_hash)
      expect(tmpl.id).to eq('tmpl-1')
      expect(tmpl.template_id).to eq('invoice-basic')
      expect(tmpl.title).to eq('Basic Invoice')
      expect(tmpl.short_description).to eq('A simple invoice template')
      expect(tmpl.tags).to eq(%w[business finance])
      expect(tmpl.sample_data).to eq('company' => 'Acme')
      expect(tmpl.author_name).to eq('CloudLayer')
    end

    it 'stores unknown fields in extra' do
      tmpl = described_class.from_hash(template_hash)
      expect(tmpl.extra[:unknown_future_field]).to eq('stored in extra')
    end
  end

  describe CloudLayerio::Responses::ResponseHeaders do
    it 'parses cl-* headers from HTTP response' do
      headers = described_class.from_http_headers(
        'cl-worker-job-id' => 'wj-123',
        'cl-cluster-id' => 'cluster-1',
        'cl-worker' => 'worker-2',
        'cl-bandwidth' => '2048',
        'cl-process-time' => '1500',
        'cl-calls-remaining' => '950',
        'cl-charged-time' => '2000',
        'cl-bandwidth-cost' => '0.01',
        'cl-process-time-cost' => '0.05',
        'cl-api-credit-cost' => '1.0'
      )
      expect(headers.worker_job_id).to eq('wj-123')
      expect(headers.cluster_id).to eq('cluster-1')
      expect(headers.worker).to eq('worker-2')
      expect(headers.bandwidth).to eq(2048)
      expect(headers.process_time).to eq(1500)
      expect(headers.calls_remaining).to eq(950)
      expect(headers.charged_time).to eq(2000)
      expect(headers.bandwidth_cost).to eq(0.01)
      expect(headers.process_time_cost).to eq(0.05)
      expect(headers.api_credit_cost).to eq(1.0)
    end

    it 'handles missing headers as nil' do
      headers = described_class.from_http_headers('cl-worker-job-id' => 'wj-123')
      expect(headers.worker_job_id).to eq('wj-123')
      expect(headers.bandwidth).to be_nil
      expect(headers.process_time_cost).to be_nil
    end

    it 'handles non-numeric values gracefully' do
      headers = described_class.from_http_headers(
        'cl-bandwidth' => 'invalid',
        'cl-bandwidth-cost' => 'bad'
      )
      expect(headers.bandwidth).to be_nil
      expect(headers.bandwidth_cost).to be_nil
    end
  end

  describe CloudLayerio::Responses::ConversionResult do
    it 'wraps a Job (v2 response)' do
      job = CloudLayerio::Responses::Job.from_hash('id' => '1', 'status' => 'pending')
      headers = CloudLayerio::Responses::ResponseHeaders.new(worker_job_id: 'wj-1')
      result = described_class.new(data: job, headers: headers, status: 200)
      expect(result.job?).to be true
      expect(result.binary?).to be false
      expect(result.job.id).to eq('1')
      expect(result.bytes).to be_nil
    end

    it 'wraps binary data (v1 response)' do
      headers = CloudLayerio::Responses::ResponseHeaders.new(worker_job_id: 'wj-1')
      result = described_class.new(data: 'PDF binary data', headers: headers, status: 200, filename: 'doc.pdf')
      expect(result.binary?).to be true
      expect(result.job?).to be false
      expect(result.bytes).to eq('PDF binary data')
      expect(result.filename).to eq('doc.pdf')
      expect(result.job).to be_nil
    end
  end
end
