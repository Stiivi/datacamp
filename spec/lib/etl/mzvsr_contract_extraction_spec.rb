# encoding: utf-8

require 'spec_helper'

describe Etl::MzvsrContractExtraction do
  let(:uri) { 'http://www.mzv.sk/servlet/content?MT=/App/WCM/main.nsf/vw_ByID/ID_BDFA0F8449A80739C125763500337369_SK&OpenDocument=Y&LANG=SK&PAGE_MEDZINARODNEZMLUVY-ALL-DWMCEA-7XRF9N=2&MENU=medzinarodne_zmluvy-vsetky_zmluvy&TG=BlankMaster&URL=/LDM/contractmzv.nsf/(vw_ByID)/ID_07CEBD90AC7FC385C1257AFE0039DF63' }

  let(:extractor) { described_class.new(uri) }

  describe '#uri' do
    it 'returns uri of downloaded document' do
      expect(extractor.uri).to eql(uri)
    end
  end

  describe '#download' do
    it 'downloads html of the document' do
      VCR.use_cassette('mzvsr_contract') do
        extractor.download

        expect(extractor.content).not_to be_nil
      end
    end
  end

  describe '#parse' do
    it 'parses downloaded document' do
      VCR.use_cassette('mzvsr_contract') do
        extractor.download

        extractor.parse

        expect(extractor.attributes).to eql(
          uri: uri,
          title_sk: 'Zmluva medzi Slovenskou republikou a Srbskou republikou o medzinárodnej cestnej osobnej a nákladnej doprave',
          title_en: 'Agreement between the Slovak Republic and the Republic of Serbia on International Transport of Passengers and Goods by Road',
          country: 'Srbsko',
          place: 'Bratislava',
          signed_on: Date.parse('2013-01-22'),
          valid_from: Date.parse('2014-02-02'),
          law_index: '13/2014',
          type: nil,
          priority: true,
          administrator: 'Ministerstvo dopravy, pôšt a telekomunikácií',
          protocol_number: 'MBZ'
        )
      end
    end
  end

  describe '#save' do
    it 'saves attributes' do
      pending
    end

    it 'updates existing contracts' do
      pending
    end
  end
end
