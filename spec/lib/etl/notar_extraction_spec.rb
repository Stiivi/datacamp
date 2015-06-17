# -*- encoding : utf-8 -*-
require 'spec_helper'

class Kernel::DsNotary; end
class Kernel::DsNotaryEmployee; end

describe Etl::NotarExtraction do
  
  before :each do
    @extractor = Etl::NotarExtraction.new(1, 2,2675)
    
    #for some reason this does is not included in the transaction and has to be cleaned manually
    #Staging::StaNotar.delete_all
  end
  
  it 'should successfully init an instance' do
    @extractor.start_id.should == 1
    @extractor.batch_limit.should == 2
    @extractor.id.should == 2675
  end
  
  it 'should download a document' do
    VCR.use_cassette('etl/notar_extraction/notari_2675') do
      @extractor.download(2675).should_not be_nil
    end
  end
  
  it 'should return a correctly formatted document url' do
    @extractor.document_url(12345).should == URI.encode("http://www.notar.sk/Úvod/Notárskecentrálneregistre/Notárskeúrady/Notárskeúradydetail.aspx?id=12345")
  end
  
  it 'should return a configuration' do
    EtlConfiguration.create(:name => 'notary_extraction')
    @extractor.config.should_not be_nil
  end
  
  it 'should update last processed id' do
    config = EtlConfiguration.create(:name => 'notary_extraction', :last_processed_id => 1)
    @extractor.update_last_processed
    config.reload.last_processed_id.should == 2675
  end
  
  it 'should not update last processed id if its not larger than current value' do
    config = EtlConfiguration.create(:name => 'notary_extraction', :last_processed_id => 2676)
    @extractor.update_last_processed
    config.reload.last_processed_id.should == 2676
  end
  
  it 'should save extracted information to the database' do
    Kernel::DsNotary.should_receive(:find_by_doc_id)
    Kernel::DsNotary.should_receive(:create)
    Kernel::DsNotaryEmployee.should_receive(:find_or_create_by_first_name_and_last_name_and_title_and_date_start_and_date_end_and_languages).at_least(7).times

    VCR.use_cassette('etl/notar_extraction/notari_2675') do
      document = @extractor.download(2675)
      notari_hash = @extractor.digest(document)
      @extractor.save(notari_hash)
    end
  end
  
  it 'should update the last processed id and schedule a new job if it is the batch limit and something was processed within that limit.' do
    EtlConfiguration.create(:name => 'notary_extraction', :last_processed_id => 2672, :batch_limit => 5)
    Delayed::Job.stub(:enque)
    extractor = Etl::NotarExtraction.new(2670, 5,2675)
    Delayed::Job.should_receive(:enqueue).exactly(6).times
    extractor.after(nil)
  end
  
  it 'should update the start id if it hits the batch limit and there was nothing processed during current batch.' do
    config = EtlConfiguration.create(:name => 'notary_extraction', :last_processed_id => 2669, :batch_limit => 5)
    Delayed::Job.stub(:enque)
    extractor = Etl::NotarExtraction.new(2670, 5,2675)
    Delayed::Job.should_not_receive(:enqueue)
    extractor.after(nil)
    config.reload.start_id.should == 2670
  end
  
  it 'should not save the same thing twice into the database' do
    Kernel::DsNotary.should_receive(:find_by_doc_id)
    Kernel::DsNotary.should_receive(:create)
    Kernel::DsNotaryEmployee.should_receive(:find_or_create_by_first_name_and_last_name_and_title_and_date_start_and_date_end_and_languages).at_least(7).times

    VCR.use_cassette('etl/notar_extraction/notari_2675') do
      document = @extractor.download(2675)
      notari_hash = @extractor.digest(document)
      @extractor.save(notari_hash) and @extractor.save(notari_hash)
    end
  end
  
  it 'should have a perform method that downloads, parses and saves to the db' do
    Kernel::DsNotary.should_receive(:find_by_doc_id)
    Kernel::DsNotary.should_receive(:create)
    Kernel::DsNotaryEmployee.should_receive(:find_or_create_by_first_name_and_last_name_and_title_and_date_start_and_date_end_and_languages).at_least(7).times

    VCR.use_cassette('etl/notar_extraction/notari_2675') do
      config = EtlConfiguration.create(:name => 'notary_extraction', :last_processed_id => 2669, :batch_limit => 5)
      @extractor.perform
      config.reload.last_processed_id.should == 2675
    end
  end
  
  describe 'parsing' do
    it 'should test and accept valid documents' do
      VCR.use_cassette('etl/notar_extraction/notari_2675') do
        document = @extractor.download(2675)
        @extractor.is_acceptable?(document).should be_true
      end
    end
    
    it 'should test and not accept invalid documents' do
      VCR.use_cassette('etl/notar_extraction/notari_0') do
        document = @extractor.download(0)
        @extractor.is_acceptable?(document).should be_false
      end
    end

    it 'should get information from a document' do
      VCR.use_cassette('etl/notar_extraction/notari_2675') do
        document = @extractor.download(2675)
        hash = @extractor.digest(document)
        hash[:doc_id].should == 2675
        hash[:name].should == 'Belková Zora'
        hash[:form].should == 'Notársky úrad'
        hash[:street].should == 'Skuteckého 16'
        hash[:city].should == 'Banská Bystrica'
        hash[:zip].should == '974 01'
        hash[:url].should == "http://www.notar.sk/%C3%9Avod/Not%C3%A1rskecentr%C3%A1lneregistre/Not%C3%A1rske%C3%BArady/Not%C3%A1rske%C3%BAradydetail.aspx?id=2675"
      end
    end
  
    it "should parse 'Ľubica Rexová' out of a document with the name 'NÚ JUDr. Ľubica Rexová'" do
      VCR.use_cassette('etl/notar_extraction/notari_16544') do
        extractor = Etl::NotarExtraction.new(16544, 1,16544)
        document = extractor.download(16544)
        hash = extractor.digest(document)
        hash[:name].should == 'Ľubica Rexová'
      end
    end
    
    it "should parse 'Ľubica Rexová' out of a document with the name 'NÚ JUDr. Ľubica Rexová'" do
      VCR.use_cassette('etl/notar_extraction/notari_16544') do
        extractor = Etl::NotarExtraction.new(16544, 1,16544)
        document = extractor.download(16544)
        hash = extractor.digest(document)
        hash[:name].should == 'Ľubica Rexová'
      end
    end
    
    it "should parse 'Nagyová Mária' out of a document with the name 'Nagyová Mária'" do
      VCR.use_cassette('etl/notar_extraction/notari_15417') do
        extractor = Etl::NotarExtraction.new(15417, 1,15417)
        document = extractor.download(15417)
        hash = extractor.digest(document)
        hash[:name].should == 'Nagyová Mária'
      end
    end
    
    it "should parse 'Kokindová Eleonóra' out of a document with the name 'Kokindová Eleonóra, JUDr.'" do
      VCR.use_cassette('etl/notar_extraction/notari_15065') do
        extractor = Etl::NotarExtraction.new(15065, 1,15065)
        document = extractor.download(15065)
        hash = extractor.digest(document)
        hash[:name].should == 'Kokindová Eleonóra'
      end
    end
    
    it "should parse 'Marta Vaľková' out of a document with the name 'Notársky úrad Bardejov - Marta Vaľková JUDr.'" do
      VCR.use_cassette('etl/notar_extraction/notari_15000') do
        extractor = Etl::NotarExtraction.new(15000, 1,15000)
        document = extractor.download(15000)
        hash = extractor.digest(document)
        hash[:name].should == 'Marta Vaľková'
      end
    end
    
    it "should parse 'Floriánová Ľubica' out of a document with the name 'Floriánová Ľubica JUDr.'" do
      VCR.use_cassette('etl/notar_extraction/notari_14963') do
        extractor = Etl::NotarExtraction.new(14963, 1,14963)
        document = extractor.download(14963)
        hash = extractor.digest(document)
        hash[:name].should == 'Floriánová Ľubica'
      end
    end

    it "should parse 'Korenková' out of a document with the name 'NU Mgr. Korenková'" do
      VCR.use_cassette('etl/notar_extraction/notari_13963') do
        extractor = Etl::NotarExtraction.new(13963, 1,13963)
        document = extractor.download(13963)
        hash = extractor.digest(document)
        hash[:name].should == 'Korenková'
      end
    end
    
    it 'should dump testing data' do
      VCR.use_cassette('etl/notar_extraction/notari_13537') do
        extractor = Etl::NotarExtraction.new(13537, 1,13537)
        document = extractor.download(13537)
        hash = extractor.digest(document)
        hash.should be_nil
      end
    end
    
    it "should parse 'Štefan Štefanko' out of a document with the name 'JUDr. Štefan Štefanko'" do
      VCR.use_cassette('etl/notar_extraction/notari_6140') do
        extractor = Etl::NotarExtraction.new(6140, 1,6140)
        document = extractor.download(6140)
        hash = extractor.digest(document)
        hash[:name].should == 'Štefan Štefanko'
      end
    end
    
    it "should parse 'Miloš Kaan' out of a document with the name 'Notársky úrad - JUDr.Miloš Kaan '" do
      VCR.use_cassette('etl/notar_extraction/notari_4829') do
        extractor = Etl::NotarExtraction.new(4829, 1,4829)
        document = extractor.download(4829)
        hash = extractor.digest(document)
        hash[:name].should == 'Miloš Kaan'
      end
    end
    
    it "should parse 'Zuzana Lutašová' out of a document with the name 'JUDr. Zuzana Lutašová'" do
      VCR.use_cassette('etl/notar_extraction/notari_4094') do
        extractor = Etl::NotarExtraction.new(4094, 1,4094)
        document = extractor.download(4094)
        hash = extractor.digest(document)
        hash[:name].should == 'Zuzana Lutašová'
      end
    end
    
    it "should parse 'Horváthová' out of a document with the name 'Notársky úrad JUDr. Horváthová'" do
      VCR.use_cassette('etl/notar_extraction/notari_3834') do
        extractor = Etl::NotarExtraction.new(3834, 1,3834)
        document = extractor.download(3834)
        hash = extractor.digest(document)
        hash[:name].should == 'Horváthová'
      end
    end
    
    it "should parse 'Soňa Šuvadová' out of a document with the name 'JUDr.- Soňa Šuvadová'" do
      VCR.use_cassette('etl/notar_extraction/notari_3534') do
        extractor = Etl::NotarExtraction.new(3534, 1,3534)
        document = extractor.download(3534)
        hash = extractor.digest(document)
        hash[:name].should == 'Soňa Šuvadová'
      end
    end
    
    it "should parse 'Tatiany Bradáčovej' out of a document with the name 'Notársky úrad JUDr. Tatiany Bradáčovej'" do
      VCR.use_cassette('etl/notar_extraction/notari_3070') do
        extractor = Etl::NotarExtraction.new(3070, 1,3070)
        document = extractor.download(3070)
        hash = extractor.digest(document)
        hash[:name].should == 'Tatiany Bradáčovej'
      end
    end
    
    it "should parse 'Ivona Žilíková' out of a document with the name 'Notársky úrad, Mgr. Ivona Žilíková'" do
      VCR.use_cassette('etl/notar_extraction/notari_1578') do
        extractor = Etl::NotarExtraction.new(1578, 1,1578)
        document = extractor.download(1578)
        hash = extractor.digest(document)
        hash[:name].should == 'Ivona Žilíková'
      end
    end
    
    it "should parse 'Telepčák Vladimír' out of a document with the name 'Telepčák, Vladimír, JUDr.'" do
      VCR.use_cassette('etl/notar_extraction/notari_1380') do
        extractor = Etl::NotarExtraction.new(1380, 1,1380)
        document = extractor.download(1380)
        hash = extractor.digest(document)
        hash[:name].should == 'Telepčák Vladimír'
      end
    end
    
    it "should parse 'Márie Kvasnovskej' out of a document with the name 'notárky Márie Kvasnovskej'" do
      VCR.use_cassette('etl/notar_extraction/notari_1241') do
        extractor = Etl::NotarExtraction.new(1241, 1,1241)
        document = extractor.download(1241)
        hash = extractor.digest(document)
        hash[:name].should == 'Márie Kvasnovskej'
      end
    end
    
    it "should parse 'Rybánska Vlasta' out of a document with the name 'Rybánska Vlasta JUDr.'" do
      VCR.use_cassette('etl/notar_extraction/notari_1255') do
        extractor = Etl::NotarExtraction.new(1255, 1,1255)
        document = extractor.download(1255)
        hash = extractor.digest(document)
        hash[:name].should == 'Rybánska Vlasta'
      end
    end
  end
  
  describe 'checking' do
    it 'should get a list of active documents' do
      VCR.use_cassette('etl/notar_extraction/notari_list') do
        active_docs = Etl::NotarExtraction.get_active_docs
        active_docs.count.should be > 1

        active_docs.each do |doc_id|
          doc_id.should match_regex /[0-9]{2,}/
        end
      end
    end
    
    it 'should return a correctly formatted list url' do
      Etl::NotarExtraction.list_url.should == URI.encode("http://www.notar.sk/Úvod/Notárskecentrálneregistre/Notárskeúrady.aspx")
    end
  end
end
