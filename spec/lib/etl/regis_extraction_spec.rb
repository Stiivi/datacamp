# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Etl::RegisExtraction do

  before :each do
    @extractor = Etl::RegisExtraction.new(1, 2,500000)

    #for some reason this does is not included in the transaction and has to be cleaned manually
    Staging::StaRegisMain.delete_all
  end

  it 'should successfully init an instance' do
    @extractor.start_id.should == 1
    @extractor.batch_limit.should == 2
    @extractor.id.should == 500000
  end

  it 'should download a document' do
    VCR.use_cassette('regis_500000') do
      @extractor.download(500000).should_not be_nil
    end
  end

  it 'should return a correctly formatted document url' do
    @extractor.document_url(12345).should == "http://www.statistics.sk/pls/wregis/detail?wxidorg=12345"
  end

  it 'should return a configuration' do
    EtlConfiguration.create(:name => 'regis_extraction')
    @extractor.config.should_not be_nil
  end

  it 'should update last processed id' do
     config = EtlConfiguration.create(:name => 'regis_extraction', :last_processed_id => 1)
     @extractor.update_last_processed
     config.reload.last_processed_id.should == 500000
  end

  it 'should not update last processed id if its not larger than current value' do
    config = EtlConfiguration.create(:name => 'regis_extraction', :last_processed_id => 500001)
    @extractor.update_last_processed
    config.reload.last_processed_id.should == 500001
  end

  it 'should save extracted information to the database' do
    VCR.use_cassette('regis_500000') do
      document = @extractor.download(500000)
      organisation_hash = @extractor.digest(document)
      @extractor.save(organisation_hash)
      Staging::StaRegisMain.count.should == 1
    end
  end

  it 'should update the last processed id and schedule a new job if it is the batch limit and something was processed within that limit.' do
    EtlConfiguration.create(:name => 'regis_extraction', :last_processed_id => 499998, :batch_limit => 5)
    Delayed::Job.stub(:enque)
    extractor = Etl::RegisExtraction.new(499995, 5, 500000)
    Delayed::Job.should_receive(:enqueue).exactly(6).times
    extractor.after(nil)
  end

  it 'should update the start id if it hits the batch limit and there was nothing processed during current batch.' do
    config = EtlConfiguration.create(:name => 'regis_extraction', :last_processed_id => 499994, :batch_limit => 5)
    Delayed::Job.stub(:enque)
    extractor = Etl::RegisExtraction.new(499995, 5, 500000)
    Delayed::Job.should_not_receive(:enqueue)
    extractor.after(nil)
    config.reload.start_id.should == 499995
  end

  it 'should not save the same thing twice into the database' do
    VCR.use_cassette('regis_500000') do
      document = @extractor.download(500000)
      organisation_hash = @extractor.digest(document)
      @extractor.save(organisation_hash) and @extractor.save(organisation_hash)
      Staging::StaRegisMain.count.should == 1
    end
  end

  it 'should have a perform method that downloads, parses and saves to the db' do
    VCR.use_cassette('regis_500000') do
      config = EtlConfiguration.create(:name => 'regis_extraction', :last_processed_id => 499998, :batch_limit => 5)
      @extractor.perform
      Staging::StaRegisMain.count.should == 1
      config.reload.last_processed_id.should == 500000
    end
  end

  it 'should update the last_processed_id only when something was processed' do
    VCR.use_cassette('regis_0') do
      config = EtlConfiguration.create(:name => 'regis_extraction', :last_processed_id => 499998, :batch_limit => 5)
      extractor = Etl::RegisExtraction.new(1, 2, 0)
      extractor.perform
      config.reload.last_processed_id.should == 499998
    end
  end

  describe 'parsing' do
    it 'should test and accept documents that have a something in a div with a class "telo"' do
      VCR.use_cassette('regis_500000') do
        document = @extractor.download(500000)
        @extractor.is_acceptable?(document).should be_true
      end
    end

    it 'should test and not accept documents that do not have a V in the h2 header' do
      VCR.use_cassette('regis_0') do
        document = @extractor.download(0)
        @extractor.is_acceptable?(document).should be_false
      end
    end

    it 'should get information from a document' do
      VCR.use_cassette('regis_500000') do
        document = @extractor.download(500000)
        hash = @extractor.digest(document)
        hash[:doc_id].should == 500000
        hash[:ico].should == "34797564"
        hash[:name].should == "Ján Strmeň"
        hash[:legal_form].should == "101"
        hash[:date_start].should == Date.parse("Thu, 14 Dec 2000")
        hash[:date_end].should == Date.parse("Tue, 25 Nov 2008")
        hash[:address].should == "Utekáč 827/25,  985 06 Utekáč"
        hash[:region].should == "Poltár"
        hash[:activity1].should == "55200"
        hash[:activity2].should == "55210"
        hash[:ownership].should == "2"
        hash[:size].should == "00"
        hash[:source_url].should == "http://www.statistics.sk/pls/wregis/detail?wxidorg=500000"
      end
    end


    it 'should get information from another document' do
      VCR.use_cassette('regis_102034') do
        @extractor = Etl::RegisExtraction.new(1, 2, 102034)
        document = @extractor.download(102034)
        hash = @extractor.digest(document)
        hash[:doc_id].should == 102034
        hash[:ico].should == "30090091"
        hash[:name].should == "Jozef Smaženka - Bitúnok Dojč"
        hash[:legal_form].should == "101"
        hash[:date_start].should == Date.parse("Mon, 22 Jul 1991")
        hash[:date_end].should == Date.parse("Mon, 09 Sep 2013")
        hash[:address].should == "Dojč 447,  906 02 Dojč"
        hash[:region].should == "Senica"
        hash[:activity1].should == "49410"
        hash[:activity2].should == "60240"
        hash[:ownership].should == "2"
        hash[:size].should == "  "
        hash[:source_url].should == "http://www.statistics.sk/pls/wregis/detail?wxidorg=102034"
      end
    end

    it 'should get information from another document' do
      VCR.use_cassette('regis_1332604') do
        @extractor = Etl::RegisExtraction.new(1, 2, 1332604)
        document = @extractor.download(1332604)
        hash = @extractor.digest(document)
        hash[:doc_id].should == 1332604
        hash[:ico].should == "42311748"
        hash[:name].should == "Bc. Iveta Purgatová"
        hash[:legal_form].should == "105"
        hash[:date_start].should == Date.parse("Wed, 18 Dec 2013")
        hash[:date_end].should == nil
        hash[:address].should == "Strelníky 67,  976 55 Strelníky"
        hash[:region].should == "Banská Bystrica"
        hash[:activity1].should == "66220"
        hash[:activity2].should == "67200"
        hash[:ownership].should == "2"
        hash[:size].should == "  "
        hash[:source_url].should == "http://www.statistics.sk/pls/wregis/detail?wxidorg=1332604"
      end
    end
  end

end
