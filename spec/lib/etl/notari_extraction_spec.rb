# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Etl::NotariExtraction do
  
  before :each do
    @extractor = Etl::NotariExtraction.new(1, 2,2675)
    
    #for some reason this does is not included in the transaction and has to be cleaned manually
    Staging::StaNotari.delete_all
  end
  
  it 'should successfully init an instance' do
    @extractor.start_id.should == 1
    @extractor.batch_limit.should == 2
    @extractor.id.should == 2675
  end
  
  it 'should download a document' do
    VCR.use_cassette('notari_2675') do
      @extractor.download(2675).should_not be_nil
    end
  end
  
  it 'should return a correctly formatted document url' do
    @extractor.document_url(12345).should == URI.encode("http://www.notar.sk/Úvod/Notárskecentrálneregistre/Notárskeúrady/Notárskeúradydetail.aspx?id=12345")
  end
  
  it 'should return a configuration' do
    EtlConfiguration.create(:name => 'notari_extraction')
    @extractor.config.should_not be_nil
  end
  
  it 'should update last processed id' do
    config = EtlConfiguration.create(:name => 'notari_extraction', :last_processed_id => 1)
    @extractor.update_last_processed
    config.reload.last_processed_id.should == 2675
  end
  
  it 'should not update last processed id if its not larger than current value' do
    config = EtlConfiguration.create(:name => 'notari_extraction', :last_processed_id => 2676)
    @extractor.update_last_processed
    config.reload.last_processed_id.should == 2676
  end
  
  it 'should save extracted information to the database' do
    VCR.use_cassette('notari_2675') do
      document = @extractor.download(2675)
      notari_hash = @extractor.digest(document)
      @extractor.save(notari_hash)
      Staging::StaNotari.count.should == 7
    end
  end
  
  it 'should update the last processed id and schedule a new job if it is the batch limit and something was processed within that limit.' do
    EtlConfiguration.create(:name => 'notari_extraction', :last_processed_id => 2672, :batch_limit => 5)
    Delayed::Job.stub(:enque)
    extractor = Etl::NotariExtraction.new(2670, 5,2675)
    Delayed::Job.should_receive(:enqueue).exactly(6).times
    extractor.after(nil)
  end
  
  it 'should update the start id if it hits the batch limit and there was nothing processed during current batch.' do
    config = EtlConfiguration.create(:name => 'notari_extraction', :last_processed_id => 2669, :batch_limit => 5)
    Delayed::Job.stub(:enque)
    extractor = Etl::NotariExtraction.new(2670, 5,2675)
    Delayed::Job.should_not_receive(:enqueue)
    extractor.after(nil)
    config.reload.start_id.should == 2670
  end
  
  it 'should not save the same thing twice into the database' do
    VCR.use_cassette('notari_2675') do
      document = @extractor.download(2675)
      notari_hash = @extractor.digest(document)
      @extractor.save(notari_hash) and @extractor.save(notari_hash)
      Staging::StaNotari.count.should == 7
    end
  end
  
  it 'should have a perform method that downloads, parses and saves to the db' do
    VCR.use_cassette('notari_2675') do
      config = EtlConfiguration.create(:name => 'notari_extraction', :last_processed_id => 2669, :batch_limit => 5)
      @extractor.perform
      Staging::StaNotari.count.should == 7
      config.reload.last_processed_id.should == 2675
    end
  end
  
  describe 'parsing' do
    it 'should test and accept valid documents' do
      VCR.use_cassette('notari_2675') do
        document = @extractor.download(2675)
        @extractor.is_acceptable?(document).should be_true
      end
    end
    
    it 'should test and not accept invalid documents' do
      VCR.use_cassette('notari_0') do
        document = @extractor.download(0)
        @extractor.is_acceptable?(document).should be_false
      end
    end

    it 'should get information from a document' do
      VCR.use_cassette('notari_2675') do
        document = @extractor.download(2675)
        hash = @extractor.digest(document)
        hash[:doc_id].should == 2675
        hash[:name].should == 'Belková Zora Mgr.'
        hash[:form].should == 'Notársky úrad'
        hash[:street].should == 'Skuteckého 16'
        hash[:city].should == 'Banská Bystrica'
        hash[:zip].should == '974 01'
        hash[:url].should == "http://www.notar.sk/%C3%9Avod/Not%C3%A1rskecentr%C3%A1lneregistre/Not%C3%A1rske%C3%BArady/Not%C3%A1rske%C3%BAradydetail.aspx?id=2675"
        
        hash[:employees].should == [{:worker_name=>"JUDr. Zora Belková  (Notár)", :date_start=>"12. 9. 2002", :date_end=>"", :languages=>"Anglický jazyk (UK), Slovenský jazyk (SK), Ruský jazyk (RU), Poľský jazyk (PL), Český jazyk (CZ)"}, {:worker_name=>"Eva Babková  (Zamestnanec)", :date_start=>"2. 1. 2003", :date_end=>"", :languages=>"Slovenský jazyk (SK)"}, {:worker_name=>"Mgr. Zora Belková XXX  (Zamestnanec)", :date_start=>"5. 9. 2002", :date_end=>"", :languages=>"Ruský jazyk (RU), Anglický jazyk (UK)"}, {:worker_name=>"Jana Gerhátová  (Zamestnanec)", :date_start=>"11. 9. 2006", :date_end=>"", :languages=>"Slovenský jazyk (SK)"}, {:worker_name=>"Peter Pružina  (Zamestnanec)", :date_start=>"24. 9. 2002", :date_end=>"", :languages=>"Slovenský jazyk (SK)"}, {:worker_name=>"Martina Švecová  (Zamestnanec)", :date_start=>"5. 5. 2003", :date_end=>"", :languages=>"Slovenský jazyk (SK)"}, {:worker_name=>"JUDr. Ida Plichtová  (Bývalý zamestnanec)", :date_start=>"24. 9. 2002", :date_end=>"27. 10. 2003", :languages=>"Slovenský jazyk (SK)"}]
      end
    end
    
    
  end
end