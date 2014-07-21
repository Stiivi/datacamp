# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Etl::FoundationPageExtraction do

  before :each do
    @extractor = Etl::FoundationPageExtraction.new(1)
  end

  describe '#document_url' do
    it 'return a correctly formatted document url' do
      @extractor.document_url.should == URI.encode("http://www.ives.sk/registre/zoznamrnd.do?action=azzu&cisloStrany=1&locale=sk")
    end
  end

  describe '#download' do
    it 'return downloaded document' do
      VCR.use_cassette('foundation_page_1') do
        @extractor.download.should_not be_nil
      end
    end
  end

  describe '#document' do
    it 'return document' do
      VCR.use_cassette('foundation_page_1') do
        @extractor.document.should_not be_nil
      end
    end
  end

  describe '#is_acceptable?' do
    it 'return true for accepted page' do
       VCR.use_cassette('foundation_page_1') do
        @extractor.is_acceptable?.should be_true
      end
    end
    it 'return false for not accepted page' do
      @extractor = Etl::FoundationPageExtraction.new(50)
       VCR.use_cassette('foundation_page_50') do
        @extractor.is_acceptable?.should be_false
      end
    end
  end

  describe '#get_downloads' do
    it 'return array of ids for accepted page' do
      VCR.use_cassette('foundation_page_1') do
        downloads = @extractor.get_downloads
        downloads.size.should == 20
        downloads.first.should == 158785
        downloads.last.should == 158264
      end
    end
  end

  describe '#perform' do
    it 'perform for accpeted page' do
      VCR.use_cassette('foundation_page_1') do
        @extractor.perform
        Delayed::Job.count.should == 20
      end
    end
  end

  describe '#after' do
    it 'perform for accpeted page' do
      VCR.use_cassette('foundation_page_1') do
        @extractor.after(nil)
        Delayed::Job.count.should == 1
      end
    end
  end

end
