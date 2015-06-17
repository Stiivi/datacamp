# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Etl::FoundationPageExtraction::FoundationListingPage do
  describe '#foundation_ids' do
    it 'returns array of foundation ids from page' do
      page = VCR.use_cassette('etl/foundation_page_extraction/page_1') do
        Etl::PageLoader.load_by_get("http://www.ives.sk/registre/zoznamrnd.do?action=azzu&cisloStrany=1&locale=sk", Etl::FoundationPageExtraction::FoundationListingPage)
      end

      page.foundation_ids.each do |foundation_id|
        foundation_id.should be > 100_000
        foundation_id.should be < 300_000
      end
    end

    it 'returns empty array if there is no organization id on page' do
      page = VCR.use_cassette('etl/foundation_page_extraction/page_99') do
        Etl::PageLoader.load_by_get("http://www.ives.sk/registre/zoznamrnd.do?action=azzu&cisloStrany=99&locale=sk", Etl::FoundationPageExtraction::FoundationListingPage)
      end

      page.foundation_ids.should eq []
    end
  end
end

describe Etl::FoundationPageExtraction do
  subject { Etl::FoundationPageExtraction.new(1) }

  describe '#document_url' do
    it 'return a correctly formatted document url' do
      subject.document_url.should == URI.encode("http://www.ives.sk/registre/zoznamrnd.do?action=azzu&cisloStrany=1&locale=sk")
    end
  end

  describe '#perform' do
    it 'perform for accepted page' do
      VCR.use_cassette('etl/foundation_page_extraction/page_1') do
        Delayed::Job.should_receive(:enqueue).exactly(20).times
        subject.perform
      end
    end
  end

  describe '#after' do
    it 'perform for accepted page' do
      VCR.use_cassette('etl/foundation_page_extraction/page_1') do
        Delayed::Job.should_receive(:enqueue).with(instance_of(described_class))
        subject.after(nil)
      end
    end
  end
end
