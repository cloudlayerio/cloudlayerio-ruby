# cloudlayerio

Official Ruby SDK for the [cloudlayer.io](https://cloudlayer.io) document generation API.

[![Gem Version](https://badge.fury.io/rb/cloudlayerio.svg)](https://rubygems.org/gems/cloudlayerio)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Convert HTML, URLs, and templates to PDF and images. Supports file conversions (DOCX to PDF, PDF to DOCX), PDF merging, and a visual template editor.

## Requirements

- Ruby >= 3.1
- One runtime dependency: `base64` gem (bundled with Ruby; extracted to a separate gem in Ruby 3.4+)

## Installation

Add to your Gemfile:

```ruby
gem "cloudlayerio", "~> 0.1"
```

Then run `bundle install`. Or install directly:

```bash
gem install cloudlayerio
```

## Quick Start

```ruby
require "cloudlayerio"

# v2 (async) — returns a Job object
client = CloudLayerio::Client.new(api_key: "your-api-key", api_version: :v2)
result = client.url_to_pdf(url: "https://example.com", async: true, storage: true)
job = client.wait_for_job(result.job.id)
data = client.download_job_result(job)
File.binwrite("output.pdf", data)

# v1 (sync) — returns binary data directly
client = CloudLayerio::Client.new(api_key: "your-api-key", api_version: :v1)
result = client.url_to_pdf(url: "https://example.com")
File.binwrite("output.pdf", result.bytes)
```

## Configuration

```ruby
client = CloudLayerio::Client.new do |config|
  config.api_key = "your-api-key"     # Required
  config.api_version = :v2             # Required — :v1 or :v2
  config.base_url = "https://api.cloudlayer.io"  # Default
  config.timeout = 30                  # Seconds, default 30
  config.max_retries = 2              # 0-5, default 2
  config.user_agent = "my-app/1.0"    # Custom user agent
  config.headers = { "X-Custom" => "value" }  # Extra headers
end
```

## Conversion Methods

### URL to PDF

```ruby
result = client.url_to_pdf(
  url: "https://example.com",
  format: "a4",
  print_background: true,
  margin: CloudLayerio::Options::Margin.new(top: "10px", bottom: "10px")
)
```

### URL to Image

```ruby
result = client.url_to_image(
  url: "https://example.com",
  image_type: "png",
  quality: 90
)
```

### HTML to PDF

```ruby
html = CloudLayerio::Util::HtmlUtil.encode_html("<h1>Hello World</h1><p>Generated with cloudlayer.io</p>")
result = client.html_to_pdf(html: html, format: "letter")
```

### HTML to Image

```ruby
html = CloudLayerio::Util::HtmlUtil.encode_html("<div style='padding:20px'>Screenshot</div>")
result = client.html_to_image(html: html, image_type: "png")
```

### Template to PDF

```ruby
result = client.template_to_pdf(
  template_id: "your-template-id",
  data: { name: "John Doe", invoice_number: "INV-001" }
)
```

### Template to Image

```ruby
result = client.template_to_image(
  template_id: "your-template-id",
  data: { title: "Certificate of Completion" },
  image_type: "png"
)
```

### DOCX to PDF

```ruby
result = client.docx_to_pdf(file: "/path/to/document.docx")
```

### DOCX to HTML

```ruby
result = client.docx_to_html(file: "/path/to/document.docx")
```

### PDF to DOCX

```ruby
result = client.pdf_to_docx(file: "/path/to/document.pdf")
```

### Merge PDFs

```ruby
result = client.merge_pdfs(
  batch: CloudLayerio::Options::Batch.new(urls: [
    "https://example.com/page1.pdf",
    "https://example.com/page2.pdf"
  ])
)
```

## Working with v2 Results

v2 API returns a Job object. Poll for completion, then download:

```ruby
client = CloudLayerio::Client.new(api_key: "your-key", api_version: :v2)

# Start conversion
result = client.url_to_pdf(url: "https://example.com", async: true, storage: true)
puts "Job created: #{result.job.id}"

# Wait for completion (polls every 5 seconds, up to 5 minutes)
job = client.wait_for_job(result.job.id)
puts "Job completed: #{job.status}"

# Download the result
pdf_data = client.download_job_result(job)
File.binwrite("output.pdf", pdf_data)
```

## Data Management

### Jobs

```ruby
jobs = client.list_jobs          # Up to 10 most recent
job = client.get_job("job-id")
```

### Assets

```ruby
assets = client.list_assets      # Up to 10 most recent
asset = client.get_asset("asset-id")
```

### Storage

```ruby
storages = client.list_storage
detail = client.get_storage("storage-id")

# Create storage configuration
resp = client.add_storage(
  title: "My S3",
  region: "us-east-1",
  access_key_id: "AKIA...",
  secret_access_key: "...",
  bucket: "my-bucket"
)

# Delete storage configuration
client.delete_storage("storage-id")
```

### Account

```ruby
account = client.get_account
puts "Email: #{account.email}, Calls: #{account.calls}/#{account.calls_limit}"

status = client.get_status
puts status.status  # "ok "
```

### Templates

```ruby
templates = client.list_templates(type: "pdf", category: "invoice")
template = client.get_template("template-id")
```

## Error Handling

```ruby
begin
  result = client.url_to_pdf(url: "https://example.com")
rescue CloudLayerio::AuthError => e
  puts "Authentication failed: #{e.message} (#{e.status_code})"
rescue CloudLayerio::RateLimitError => e
  puts "Rate limited, retry after #{e.retry_after} seconds"
rescue CloudLayerio::ApiError => e
  puts "API error #{e.status_code}: #{e.message}"
rescue CloudLayerio::TimeoutError => e
  puts "Request timed out: #{e.message}"
rescue CloudLayerio::NetworkError => e
  puts "Connection failed: #{e.message}"
rescue CloudLayerio::ValidationError => e
  puts "Invalid input: #{e.message}"
rescue CloudLayerio::ConfigError => e
  puts "Bad configuration: #{e.message}"
end
```

**Error hierarchy:**

```
CloudLayerio::Error < StandardError
├── ConfigError          (invalid client config)
├── ValidationError      (client-side input validation)
├── NetworkError         (connection/DNS failure)
├── TimeoutError         (request timeout)
└── ApiError             (HTTP 4xx/5xx)
    ├── AuthError        (401/403)
    └── RateLimitError   (429, includes retry_after)
```

## Advanced Options

### Viewport and Margins

```ruby
result = client.url_to_pdf(
  url: "https://example.com",
  view_port: CloudLayerio::Options::Viewport.new(width: 1920, height: 1080, is_mobile: false),
  margin: CloudLayerio::Options::Margin.new(top: "1in", bottom: "1in", left: "0.5in", right: "0.5in")
)
```

### Cookies and Authentication

```ruby
result = client.url_to_pdf(
  url: "https://example.com/dashboard",
  authentication: CloudLayerio::Options::Authentication.new(username: "user", password: "pass"),
  cookies: [CloudLayerio::Options::Cookie.new(name: "session", value: "abc123", http_only: true)]
)
```

### Async with Storage and Webhooks

```ruby
result = client.url_to_pdf(
  url: "https://example.com",
  async: true,
  storage: true,
  webhook: "https://your-app.com/webhook"
)
```

### Batch Processing

```ruby
result = client.url_to_pdf(
  batch: CloudLayerio::Options::Batch.new(urls: [
    "https://example.com/page1",
    "https://example.com/page2"
  ])
)
```

## API Reference

Generate YARD documentation locally:

```bash
bundle exec yard doc
open doc/index.html
```

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
