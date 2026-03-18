# frozen_string_literal: true

RSpec.describe 'CloudLayerio Constants' do
  describe CloudLayerio::ApiVersion do
    it 'defines V1 and V2' do
      expect(described_class::V1).to eq('v1')
      expect(described_class::V2).to eq('v2')
    end

    it 'includes both versions in ALL' do
      expect(described_class::ALL).to contain_exactly('v1', 'v2')
    end

    it 'is frozen' do
      expect(described_class).to be_frozen
    end
  end

  describe CloudLayerio::PdfFormat do
    it 'defines all standard formats' do
      expect(described_class::LETTER).to eq('letter')
      expect(described_class::LEGAL).to eq('legal')
      expect(described_class::TABLOID).to eq('tabloid')
      expect(described_class::LEDGER).to eq('ledger')
      expect(described_class::A0).to eq('a0')
      expect(described_class::A4).to eq('a4')
      expect(described_class::A6).to eq('a6')
    end

    it 'has 11 formats in ALL' do
      expect(described_class::ALL.length).to eq(11)
    end

    it 'is frozen' do
      expect(described_class).to be_frozen
    end
  end

  describe CloudLayerio::ImageType do
    it 'defines all image types' do
      expect(described_class::PNG).to eq('png')
      expect(described_class::JPEG).to eq('jpeg')
      expect(described_class::JPG).to eq('jpg')
      expect(described_class::WEBP).to eq('webp')
      expect(described_class::SVG).to eq('svg')
    end

    it 'is frozen' do
      expect(described_class).to be_frozen
    end
  end

  describe CloudLayerio::JobStatus do
    it 'defines all statuses' do
      expect(described_class::PENDING).to eq('pending')
      expect(described_class::SUCCESS).to eq('success')
      expect(described_class::ERROR).to eq('error')
    end

    it 'is frozen' do
      expect(described_class).to be_frozen
    end
  end

  describe CloudLayerio::JobType do
    it 'defines all 12 job types' do
      expect(described_class::ALL.length).to eq(12)
      expect(described_class::HTML_PDF).to eq('html-pdf')
      expect(described_class::URL_IMAGE).to eq('url-image')
      expect(described_class::PDF_MERGE).to eq('merge-pdf')
    end

    it 'is frozen' do
      expect(described_class).to be_frozen
    end
  end

  describe CloudLayerio::WaitUntilOption do
    it 'defines all wait options' do
      expect(described_class::LOAD).to eq('load')
      expect(described_class::DOM_CONTENT_LOADED).to eq('domcontentloaded')
      expect(described_class::NETWORK_IDLE_0).to eq('networkidle0')
      expect(described_class::NETWORK_IDLE_2).to eq('networkidle2')
    end

    it 'is frozen' do
      expect(described_class).to be_frozen
    end
  end
end
