# frozen_string_literal: true

RSpec.describe CloudLayerio::Util::HtmlUtil do
  describe '.encode_html' do
    it 'Base64-encodes HTML string' do
      expect(described_class.encode_html('<h1>Hello</h1>')).to eq('PGgxPkhlbGxvPC9oMT4=')
    end

    it 'uses strict encoding (no newlines)' do
      long_html = '<html><body>' + ('x' * 200) + '</body></html>'
      encoded = described_class.encode_html(long_html)
      expect(encoded).not_to include("\n")
    end

    it 'handles empty string' do
      expect(described_class.encode_html('')).to eq('')
    end

    it 'handles UTF-8 content' do
      encoded = described_class.encode_html('<p>Héllo Wörld</p>')
      decoded = Base64.strict_decode64(encoded).force_encoding('UTF-8')
      expect(decoded).to eq('<p>Héllo Wörld</p>')
    end
  end
end
