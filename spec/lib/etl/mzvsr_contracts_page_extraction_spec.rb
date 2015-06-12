require 'spec_helper'

describe Etl::MzvsrContractsPageExtraction, slow_db: true do
  let(:extractor) { described_class.new(1) }

  describe '#document_url' do
    it 'returns corrent url for list of pages' do
      expect(extractor.document_url).to eql('http://www.mzv.sk/servlet/content?MT=/App/WCM/main.nsf/vw_ByID/zahranicna__politika&TG=BlankMaster&URL=/App/WCM/main.nsf/vw_ByID/medzinarodne_zmluvy-vsetky_zmluvy&OpenDocument=Y&LANG=SK&PAGE_MEDZINARODNEZMLUVY-ALL-DWMCEA-7XRF9N=1')
    end
  end

  describe '#download' do
    it 'returns downloaded document' do
      VCR.use_cassette('etl/mzvsr_contracts_page_extraction/page_1') do
        expect(extractor.download).not_to be_nil
      end
    end
  end

  describe '#document' do
    it 'returns parsed document' do
      VCR.use_cassette('etl/mzvsr_contracts_page_extraction/page_1') do
        expect(extractor.document).not_to be_nil
        expect(extractor.is_acceptable?).to be_true
      end
    end
  end

  describe '#is_acceptable?' do
    context 'with valid page' do
      it 'returns true' do
        VCR.use_cassette('etl/mzvsr_contracts_page_extraction/page_1') do
          expect(extractor.is_acceptable?).to be_true
        end
      end
    end

    context 'when malformed page has no links, but it is not the last page' do
      let(:extractor) { described_class.new(115) }

      it 'returns true' do
        VCR.use_cassette('etl/mzvsr_contracts_page_extraction/malformed_page') do
          extractor.download
          expect(extractor.is_acceptable?).to be_true
        end
      end
    end

    context 'with page without links' do
      let(:extractor) { described_class.new(1000000) }

      it 'returns false' do
        VCR.use_cassette('etl/mzvsr_contracts_page_extraction/page_1000000') do
          extractor.download
          expect(extractor.is_acceptable?).to be_false
        end
      end
    end
  end

  describe '#perform' do
    it 'enqueues jobs for each links' do
      VCR.use_cassette('etl/mzvsr_contracts_page_extraction/page_1') do
        Delayed::Job.should_receive(:enqueue).exactly(20).times
        extractor.perform
      end
    end
  end

  describe '#after' do
    it 'enqueues another page extraction' do
      VCR.use_cassette('etl/mzvsr_contracts_page_extraction/page_1') do
        Delayed::Job.should_receive(:enqueue).once
        extractor.after(nil)
      end
    end
  end
end
