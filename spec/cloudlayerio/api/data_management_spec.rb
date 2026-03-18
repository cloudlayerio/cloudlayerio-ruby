# frozen_string_literal: true

RSpec.describe CloudLayerio::Api::DataManagement do
  let(:client) { CloudLayerio::Client.new(api_key: 'test-key', api_version: :v2) }

  def stub_get(path, body:, status: 200)
    stub_request(:get, "https://api.cloudlayer.io/v2#{path}")
      .to_return(status: status, body: body.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_post(path, body:, status: 200)
    stub_request(:post, "https://api.cloudlayer.io/v2#{path}")
      .to_return(status: status, body: body.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_delete(path, body:, status: 200)
    stub_request(:delete, "https://api.cloudlayer.io/v2#{path}")
      .to_return(status: status, body: body.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  # --- Jobs ---

  describe '#list_jobs' do
    it 'returns array of Job objects' do
      stub_get('/jobs', body: [
        { 'id' => 'j1', 'status' => 'success' },
        { 'id' => 'j2', 'status' => 'pending' }
      ])

      jobs = client.list_jobs
      expect(jobs.length).to eq(2)
      expect(jobs[0]).to be_a(CloudLayerio::Responses::Job)
      expect(jobs[0].id).to eq('j1')
    end

    it 'is retried on 429/5xx' do
      stub = stub_request(:get, 'https://api.cloudlayer.io/v2/jobs')
        .to_return(status: 500, body: '{"error":"fail"}', headers: { 'Content-Type' => 'application/json' })
        .then
        .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

      retry_client = CloudLayerio::Client.new(api_key: 'test', api_version: :v2, max_retries: 1)
      allow_any_instance_of(CloudLayerio::Http::RetryPolicy).to receive(:sleep) # rubocop:disable RSpec/AnyInstance

      result = retry_client.list_jobs
      expect(result).to eq([])
      expect(stub).to have_been_requested.twice
    end
  end

  describe '#get_job' do
    it 'returns a Job object' do
      stub_get('/jobs/job-123', body: { 'id' => 'job-123', 'status' => 'success', 'assetUrl' => 'https://cdn.example.com/f.pdf' })

      job = client.get_job('job-123')
      expect(job.id).to eq('job-123')
      expect(job.success?).to be true
    end

    it 'validates job_id is non-empty' do
      expect { client.get_job('') }.to raise_error(CloudLayerio::ValidationError, /job_id/)
      expect { client.get_job(nil) }.to raise_error(CloudLayerio::ValidationError, /job_id/)
    end
  end

  # --- Assets ---

  describe '#list_assets' do
    it 'returns array of Asset objects' do
      stub_get('/assets', body: [{ 'id' => 'a1', 'url' => 'https://cdn.example.com/a.pdf' }])

      assets = client.list_assets
      expect(assets.length).to eq(1)
      expect(assets[0]).to be_a(CloudLayerio::Responses::Asset)
    end
  end

  describe '#get_asset' do
    it 'returns an Asset object' do
      stub_get('/assets/asset-1', body: { 'id' => 'asset-1', 'type' => 'pdf' })

      asset = client.get_asset('asset-1')
      expect(asset.id).to eq('asset-1')
    end

    it 'validates asset_id' do
      expect { client.get_asset('') }.to raise_error(CloudLayerio::ValidationError, /asset_id/)
    end
  end

  # --- Storage ---

  describe '#list_storage' do
    it 'returns array of StorageListItem' do
      stub_get('/storage', body: [{ 'id' => 's1', 'title' => 'My S3' }])

      items = client.list_storage
      expect(items.length).to eq(1)
      expect(items[0]).to be_a(CloudLayerio::Responses::StorageListItem)
      expect(items[0].title).to eq('My S3')
    end
  end

  describe '#get_storage' do
    it 'returns StorageDetail' do
      stub_get('/storage/stor-1', body: { 'id' => 'stor-1', 'title' => 'My S3' })

      detail = client.get_storage('stor-1')
      expect(detail).to be_a(CloudLayerio::Responses::StorageDetail)
      expect(detail.id).to eq('stor-1')
    end

    it 'validates storage_id' do
      expect { client.get_storage('') }.to raise_error(CloudLayerio::ValidationError)
    end
  end

  describe '#add_storage' do
    it 'creates storage and returns StorageCreateResponse' do
      stub_post('/storage', body: { 'id' => 'new-stor', 'title' => 'New S3' })

      resp = client.add_storage(
        title: 'New S3', region: 'us-east-1',
        access_key_id: 'AKIA...', secret_access_key: 'secret', bucket: 'my-bucket'
      )
      expect(resp).to be_a(CloudLayerio::Responses::StorageCreateResponse)
      expect(resp.id).to eq('new-stor')
    end

    it 'raises ApiError when storage not allowed' do
      stub_post('/storage', body: { 'allowed' => false, 'reason' => 'Plan does not support storage', 'statusCode' => 403 })

      expect {
        client.add_storage(title: 'X', region: 'us-east-1', access_key_id: 'a', secret_access_key: 's', bucket: 'b')
      }.to raise_error(CloudLayerio::ApiError, /Plan does not support storage/)
    end

    it 'is NOT retried' do
      stub_request(:post, 'https://api.cloudlayer.io/v2/storage')
        .to_return(status: 500, body: '{"error":"fail"}', headers: { 'Content-Type' => 'application/json' })

      retry_client = CloudLayerio::Client.new(api_key: 'test', api_version: :v2, max_retries: 2)

      expect {
        retry_client.add_storage(title: 'X', region: 'r', access_key_id: 'a', secret_access_key: 's', bucket: 'b')
      }.to raise_error(CloudLayerio::ApiError)
    end
  end

  describe '#delete_storage' do
    it 'returns true on success' do
      stub_delete('/storage/stor-1', body: { 'status' => 'success' })

      expect(client.delete_storage('stor-1')).to be true
    end

    it 'validates storage_id' do
      expect { client.delete_storage('') }.to raise_error(CloudLayerio::ValidationError)
    end

    it 'is NOT retried' do
      stub_request(:delete, 'https://api.cloudlayer.io/v2/storage/stor-1')
        .to_return(status: 500, body: '{"error":"fail"}', headers: { 'Content-Type' => 'application/json' })

      retry_client = CloudLayerio::Client.new(api_key: 'test', api_version: :v2, max_retries: 2)

      expect { retry_client.delete_storage('stor-1') }.to raise_error(CloudLayerio::ApiError)
    end
  end

  # --- Account ---

  describe '#get_account' do
    it 'returns AccountInfo' do
      stub_get('/account', body: {
        'email' => 'user@example.com', 'callsLimit' => 1000, 'calls' => 42,
        'subType' => 'usage', 'subActive' => true, 'uid' => 'uid-1'
      })

      acct = client.get_account
      expect(acct).to be_a(CloudLayerio::Responses::AccountInfo)
      expect(acct.email).to eq('user@example.com')
      expect(acct.calls_limit).to eq(1000)
    end
  end

  describe '#get_status' do
    it 'returns StatusResponse preserving trailing space' do
      stub_get('/getStatus', body: { 'status' => 'ok ' })

      resp = client.get_status
      expect(resp.status).to eq('ok ')
    end
  end

  # --- Templates ---

  describe '#list_templates' do
    it 'uses /v2/templates with absolute path' do
      stub = stub_request(:get, 'https://api.cloudlayer.io/v2/templates')
        .to_return(status: 200, body: '[{"id":"t1","title":"Invoice"}]',
                   headers: { 'Content-Type' => 'application/json' })

      templates = client.list_templates
      expect(stub).to have_been_requested
      expect(templates.length).to eq(1)
      expect(templates[0]).to be_a(CloudLayerio::Responses::PublicTemplate)
    end

    it 'sends filter query parameters' do
      stub = stub_request(:get, 'https://api.cloudlayer.io/v2/templates?type=pdf&category=invoice&expand=true')
        .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

      client.list_templates(type: 'pdf', category: 'invoice', expand: true)
      expect(stub).to have_been_requested
    end

    it 'uses /v2/ even with v1 client' do
      v1_client = CloudLayerio::Client.new(api_key: 'test', api_version: :v1)
      stub = stub_request(:get, 'https://api.cloudlayer.io/v2/templates')
        .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

      v1_client.list_templates
      expect(stub).to have_been_requested
    end
  end

  describe '#get_template' do
    it 'uses /v2/template/{id} with absolute path' do
      stub = stub_request(:get, 'https://api.cloudlayer.io/v2/template/tmpl-1')
        .to_return(status: 200, body: '{"id":"tmpl-1","title":"Invoice Basic"}',
                   headers: { 'Content-Type' => 'application/json' })

      tmpl = client.get_template('tmpl-1')
      expect(stub).to have_been_requested
      expect(tmpl.title).to eq('Invoice Basic')
    end

    it 'validates template_id' do
      expect { client.get_template('') }.to raise_error(CloudLayerio::ValidationError)
    end
  end

  # --- Utility Methods ---

  describe '#wait_for_job' do
    it 'returns Job when status becomes success' do
      stub_request(:get, 'https://api.cloudlayer.io/v2/jobs/job-1')
        .to_return(
          { status: 200, body: '{"id":"job-1","status":"pending"}', headers: { 'Content-Type' => 'application/json' } },
          { status: 200, body: '{"id":"job-1","status":"success","assetUrl":"https://cdn.example.com/f.pdf"}',
            headers: { 'Content-Type' => 'application/json' } }
        )

      allow(client).to receive(:sleep)

      job = client.wait_for_job('job-1', interval: 2)
      expect(job.success?).to be true
      expect(job.asset_url).to eq('https://cdn.example.com/f.pdf')
    end

    it 'raises ApiError when job fails' do
      stub_request(:get, 'https://api.cloudlayer.io/v2/jobs/job-1')
        .to_return(status: 200, body: '{"id":"job-1","status":"error","error":"timeout"}',
                   headers: { 'Content-Type' => 'application/json' })

      expect { client.wait_for_job('job-1') }
        .to raise_error(CloudLayerio::ApiError, /Job job-1 failed: timeout/)
    end

    it 'raises TimeoutError when max_wait exceeded' do
      stub_request(:get, 'https://api.cloudlayer.io/v2/jobs/job-1')
        .to_return(status: 200, body: '{"id":"job-1","status":"pending"}',
                   headers: { 'Content-Type' => 'application/json' })

      allow(client).to receive(:sleep)
      allow(Time).to receive(:now).and_return(
        Time.at(1000), # initial
        Time.at(1000), # first check
        Time.at(1400)  # after deadline (1000 + 300)
      )

      expect { client.wait_for_job('job-1') }
        .to raise_error(CloudLayerio::TimeoutError, /did not complete/)
    end

    it 'raises ValidationError when interval < 2' do
      expect { client.wait_for_job('job-1', interval: 1) }
        .to raise_error(CloudLayerio::ValidationError, /interval/)
    end

    it 'validates job_id' do
      expect { client.wait_for_job('') }
        .to raise_error(CloudLayerio::ValidationError, /job_id/)
    end

    it 'does not swallow Interrupt' do
      stub_request(:get, 'https://api.cloudlayer.io/v2/jobs/job-1')
        .to_return(status: 200, body: '{"id":"job-1","status":"pending"}',
                   headers: { 'Content-Type' => 'application/json' })

      allow(client).to receive(:sleep).and_raise(Interrupt)

      expect { client.wait_for_job('job-1') }.to raise_error(Interrupt)
    end
  end

  describe '#download_job_result' do
    it 'downloads binary from asset_url' do
      job = CloudLayerio::Responses::Job.from_hash('id' => 'j1', 'status' => 'success',
                                                    'assetUrl' => 'https://cdn.example.com/output.pdf')
      stub_request(:get, 'https://cdn.example.com/output.pdf')
        .to_return(status: 200, body: 'PDF-binary-data')

      data = client.download_job_result(job)
      expect(data).to eq('PDF-binary-data')
    end

    it 'raises ValidationError when asset_url is nil' do
      job = CloudLayerio::Responses::Job.from_hash('id' => 'j1', 'status' => 'pending')

      expect { client.download_job_result(job) }
        .to raise_error(CloudLayerio::ValidationError, /asset_url/)
    end

    it 'works with hash-like objects' do
      stub_request(:get, 'https://cdn.example.com/file.pdf')
        .to_return(status: 200, body: 'pdf-bytes')

      data = client.download_job_result(asset_url: 'https://cdn.example.com/file.pdf')
      expect(data).to eq('pdf-bytes')
    end
  end
end
