# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-17

### Added

- Client configuration with keyword arguments and block-based setup
- API version support (v1 sync binary, v2 async Job)
- **Conversion methods:**
  - `url_to_pdf` / `url_to_image` — convert URLs to PDF or image
  - `html_to_pdf` / `html_to_image` — convert Base64-encoded HTML
  - `template_to_pdf` / `template_to_image` — render server-side templates
  - `docx_to_pdf` / `docx_to_html` — convert DOCX documents (multipart upload)
  - `pdf_to_docx` — convert PDF to DOCX (multipart upload)
  - `merge_pdfs` — merge multiple PDFs from URLs
- **Data management:**
  - `list_jobs` / `get_job` — query conversion jobs
  - `list_assets` / `get_asset` — query generated assets
  - `list_storage` / `get_storage` / `add_storage` / `delete_storage` — manage S3 storage configs
  - `get_account` — retrieve account information
  - `get_status` — API health check
  - `list_templates` / `get_template` — browse public template gallery
- **Utility methods:**
  - `wait_for_job` — poll for job completion with configurable interval and timeout
  - `download_job_result` — download binary output from completed jobs
  - `CloudLayerio::Util::HtmlUtil.encode_html` — Base64-encode HTML for the API
- **HTTP transport:**
  - Retry logic with exponential backoff and jitter (429, 500-504)
  - Multipart file upload support
  - Redirect following for presigned S3 URLs
  - Configurable timeout, max retries, custom headers
- **Error handling:**
  - `AuthError` (401/403), `RateLimitError` (429 with retry_after), `ApiError` (4xx/5xx)
  - `TimeoutError`, `NetworkError`, `ValidationError`, `ConfigError`
- **Type system:**
  - Frozen constant modules (PdfFormat, ImageType, JobStatus, JobType, WaitUntilOption)
  - Option classes with keyword arguments and camelCase JSON serialization
  - Response classes with `from_hash` deserialization
  - `NOT_SET` sentinel for three-state `emulate_media_type`
- Client-side validation for all endpoints
- RSpec test suite with >97% coverage
