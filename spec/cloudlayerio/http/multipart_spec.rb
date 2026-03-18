# frozen_string_literal: true

require 'tempfile'
require 'stringio'

RSpec.describe CloudLayerio::Http::Multipart do
  describe '.build' do
    it 'returns body and content_type with boundary' do
      parts = [{ name: 'field', value: 'hello' }]
      body, content_type = described_class.build(parts)

      expect(content_type).to start_with('multipart/form-data; boundary=')
      expect(body).to include('hello')
    end

    it 'uses CRLF line endings' do
      parts = [{ name: 'field', value: 'test' }]
      body, = described_class.build(parts)

      # Every line ending should be CRLF
      expect(body).to include("\r\n")
      # No bare \n without preceding \r
      lines = body.split("\r\n")
      lines.each { |line| expect(line).not_to end_with("\n") }
    end

    it 'builds field parts correctly' do
      parts = [{ name: 'name', value: 'test-doc' }]
      body, = described_class.build(parts)

      expect(body).to include('Content-Disposition: form-data; name="name"')
      expect(body).to include('test-doc')
    end

    it 'builds file parts with filename and content-type' do
      parts = [{ name: 'file', value: 'binary-content', filename: 'doc.docx',
                 content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }]
      body, = described_class.build(parts)

      expect(body).to include('name="file"; filename="doc.docx"')
      expect(body).to include('Content-Type: application/vnd.openxmlformats')
      expect(body).to include('binary-content')
    end

    it 'defaults file content_type to application/octet-stream' do
      parts = [{ name: 'file', value: 'data', filename: 'upload.bin' }]
      body, = described_class.build(parts)

      expect(body).to include('Content-Type: application/octet-stream')
    end

    it 'ends with closing boundary (--boundary--)' do
      parts = [{ name: 'field', value: 'test' }]
      body, content_type = described_class.build(parts)

      boundary = content_type.split('boundary=').last
      expect(body).to end_with("--#{boundary}--\r\n")
    end

    it 'handles multiple parts' do
      parts = [
        { name: 'name', value: 'my-doc' },
        { name: 'timeout', value: '30000' },
        { name: 'file', value: 'pdf-bytes', filename: 'input.pdf' }
      ]
      body, = described_class.build(parts)

      expect(body).to include('name="name"')
      expect(body).to include('name="timeout"')
      expect(body).to include('name="file"')
    end

    it 'returns binary-encoded body' do
      parts = [{ name: 'file', value: "\xFF\xD8binary", filename: 'img.jpg' }]
      body, = described_class.build(parts)

      expect(body.encoding).to eq(Encoding::BINARY)
    end
  end

  describe '.read_file' do
    it 'reads from file path' do
      tmpfile = Tempfile.new(['test', '.docx'])
      tmpfile.binmode
      tmpfile.write('file-content')
      tmpfile.close

      content, filename = described_class.read_file(tmpfile.path)
      expect(content).to eq('file-content')
      expect(filename).to end_with('.docx')
    ensure
      tmpfile&.unlink
    end

    it 'reads from IO object' do
      io = StringIO.new('io-content')
      content, filename = described_class.read_file(io)
      expect(content).to eq('io-content')
      expect(filename).to eq('upload')
    end

    it 'reads from IO with path' do
      tmpfile = Tempfile.new(['named', '.pdf'])
      tmpfile.write('pdf-bytes')
      tmpfile.rewind

      content, filename = described_class.read_file(tmpfile)
      expect(content).to eq('pdf-bytes')
      expect(filename).to end_with('.pdf')
    ensure
      tmpfile&.close
      tmpfile&.unlink
    end

    it 'raises ValidationError for invalid input' do
      expect { described_class.read_file(123) }
        .to raise_error(CloudLayerio::ValidationError, /file must be/)
    end
  end
end
