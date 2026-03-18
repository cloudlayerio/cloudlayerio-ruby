# frozen_string_literal: true

# Tests that verify all response types deserialize correctly from JSON fixtures.
RSpec.describe 'Fixture deserialization' do
  describe 'Job fixtures' do
    it 'deserializes job_success.json' do
      job = CloudLayerio::Responses::Job.from_hash(fixture_hash('job_success'))
      expect(job.id).to eq('job-abc-123')
      expect(job.status).to eq('success')
      expect(job.success?).to be true
      expect(job.worker_name).to eq('worker-1')
      expect(job.process_time).to eq(1234)
      expect(job.total_cost).to eq(1.07)
      expect(job.asset_url).to eq('https://cdn.cloudlayer.io/assets/job-abc-123.pdf')
      expect(job.self_url).to eq('https://api.cloudlayer.io/v2/jobs/job-abc-123')
      expect(job.timestamp_ms).to eq(1_710_000_000_000)
    end

    it 'deserializes job_pending.json' do
      job = CloudLayerio::Responses::Job.from_hash(fixture_hash('job_pending'))
      expect(job.pending?).to be true
      expect(job.asset_url).to be_nil
    end

    it 'deserializes job_error.json' do
      job = CloudLayerio::Responses::Job.from_hash(fixture_hash('job_error'))
      expect(job.error?).to be true
      expect(job.error).to eq('Navigation timeout exceeded: 30000ms')
    end
  end

  describe 'Asset fixture' do
    it 'deserializes asset.json' do
      asset = CloudLayerio::Responses::Asset.from_hash(fixture_hash('asset'))
      expect(asset.id).to eq('asset-123')
      expect(asset.uid).to be_nil
      expect(asset.file_id).to be_nil
      expect(asset.type).to eq('pdf')
      expect(asset.url).to eq('https://cdn.cloudlayer.io/assets/asset-123.pdf')
      expect(asset.job_id).to eq('job-abc-123')
      expect(asset.timestamp_ms).to eq(1_710_000_000_000)
    end
  end

  describe 'Account fixture' do
    it 'deserializes account.json with extra fields' do
      acct = CloudLayerio::Responses::AccountInfo.from_hash(fixture_hash('account'))
      expect(acct.email).to eq('user@example.com')
      expect(acct.calls_limit).to eq(1000)
      expect(acct.sub_type).to eq('usage')
      expect(acct.credit).to eq(25.50)
      expect(acct.sub_active).to be true
      expect(acct.extra[:custom_dynamic_field]).to eq('extra-value')
    end
  end

  describe 'Storage fixtures' do
    it 'deserializes storage_list.json' do
      items = fixture_hash('storage_list').map { |h| CloudLayerio::Responses::StorageListItem.from_hash(h) }
      expect(items.length).to eq(2)
      expect(items[0].title).to eq('Production S3')
    end

    it 'deserializes storage_detail.json' do
      detail = CloudLayerio::Responses::StorageDetail.from_hash(fixture_hash('storage_detail'))
      expect(detail.id).to eq('stor-1')
      expect(detail.title).to eq('Production S3')
    end

    it 'deserializes storage_not_allowed.json' do
      resp = CloudLayerio::Responses::StorageNotAllowedResponse.from_hash(fixture_hash('storage_not_allowed'))
      expect(resp.allowed).to be false
      expect(resp.reason).to include('does not support')
      expect(resp.status_code).to eq(403)
    end

    it 'deserializes storage_create.json' do
      resp = CloudLayerio::Responses::StorageCreateResponse.from_hash(fixture_hash('storage_create'))
      expect(resp.id).to eq('stor-new-1')
      expect(resp.title).to eq('New S3 Bucket')
    end
  end

  describe 'Status fixture' do
    it 'deserializes status.json preserving trailing space' do
      resp = CloudLayerio::Responses::StatusResponse.from_hash(fixture_hash('status'))
      expect(resp.status).to eq('ok ')
    end
  end

  describe 'Template fixtures' do
    it 'deserializes template.json with all fields' do
      tmpl = CloudLayerio::Responses::PublicTemplate.from_hash(fixture_hash('template'))
      expect(tmpl.id).to eq('tmpl-invoice-1')
      expect(tmpl.template_id).to eq('invoice-basic')
      expect(tmpl.short_description).to include('professional')
      expect(tmpl.tags).to eq(%w[business finance])
      expect(tmpl.sample_data).to eq('company' => 'Acme Corp', 'invoiceNumber' => 'INV-001')
      expect(tmpl.author_name).to eq('CloudLayer')
      expect(tmpl.timestamp).to eq('_seconds' => 1_710_000, '_nanoseconds' => 0)
    end

    it 'deserializes templates_list.json' do
      list = fixture_hash('templates_list').map { |h| CloudLayerio::Responses::PublicTemplate.from_hash(h) }
      expect(list.length).to eq(2)
      expect(list[0].title).to eq('Basic Invoice')
      expect(list[1].category).to eq('receipt')
    end
  end

  describe 'Error response fixtures' do
    it 'parses 401 error' do
      data = fixture_hash('error_responses/401')
      expect(data['message']).to eq('Invalid API key')
    end

    it 'parses 429 error' do
      data = fixture_hash('error_responses/429')
      expect(data['message']).to eq('Rate limit exceeded')
    end

    it 'parses 500 error with "error" field' do
      data = fixture_hash('error_responses/500')
      expect(data['error']).to eq('Internal server error')
    end
  end
end
