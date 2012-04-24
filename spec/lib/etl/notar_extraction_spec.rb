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
    VCR.use_cassette('notari_2675') do
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
    Kernel::DsNotaryEmployee.should_receive(:find_or_create_by_first_name_and_last_name_and_title_and_date_start_and_date_end_and_languages).exactly(7).times

    VCR.use_cassette('notari_2675') do
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
    Kernel::DsNotaryEmployee.should_receive(:find_or_create_by_first_name_and_last_name_and_title_and_date_start_and_date_end_and_languages).exactly(7).times

    VCR.use_cassette('notari_2675') do
      document = @extractor.download(2675)
      notari_hash = @extractor.digest(document)
      @extractor.save(notari_hash) and @extractor.save(notari_hash)
    end
  end
  
  it 'should have a perform method that downloads, parses and saves to the db' do
    Kernel::DsNotary.should_receive(:find_by_doc_id)
    Kernel::DsNotary.should_receive(:create)
    Kernel::DsNotaryEmployee.should_receive(:find_or_create_by_first_name_and_last_name_and_title_and_date_start_and_date_end_and_languages).exactly(7).times

    VCR.use_cassette('notari_2675') do
      config = EtlConfiguration.create(:name => 'notary_extraction', :last_processed_id => 2669, :batch_limit => 5)
      @extractor.perform
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
        hash[:name].should == 'Belková Zora'
        hash[:form].should == 'Notársky úrad'
        hash[:street].should == 'Skuteckého 16'
        hash[:city].should == 'Banská Bystrica'
        hash[:zip].should == '974 01'
        hash[:url].should == "http://www.notar.sk/%C3%9Avod/Not%C3%A1rskecentr%C3%A1lneregistre/Not%C3%A1rske%C3%BArady/Not%C3%A1rske%C3%BAradydetail.aspx?id=2675"
      end
    end
  
    it "should parse 'Ľubica Rexová' out of a document with the name 'NÚ JUDr. Ľubica Rexová'" do
      VCR.use_cassette('notari_16544') do
        extractor = Etl::NotarExtraction.new(16544, 1,16544)
        document = extractor.download(16544)
        hash = extractor.digest(document)
        hash[:name].should == 'Ľubica Rexová'
      end
    end
    
    it "should parse 'Ľubica Rexová' out of a document with the name 'NÚ JUDr. Ľubica Rexová'" do
      VCR.use_cassette('notari_16544') do
        extractor = Etl::NotarExtraction.new(16544, 1,16544)
        document = extractor.download(16544)
        hash = extractor.digest(document)
        hash[:name].should == 'Ľubica Rexová'
      end
    end
    
    it "should parse 'Nagyová Mária' out of a document with the name 'Nagyová Mária'" do
      VCR.use_cassette('notari_15417') do
        extractor = Etl::NotarExtraction.new(15417, 1,15417)
        document = extractor.download(15417)
        hash = extractor.digest(document)
        hash[:name].should == 'Nagyová Mária'
      end
    end
    
    it "should parse 'Kokindová Eleonóra' out of a document with the name 'Kokindová Eleonóra, JUDr.'" do
      VCR.use_cassette('notari_15065') do
        extractor = Etl::NotarExtraction.new(15065, 1,15065)
        document = extractor.download(15065)
        hash = extractor.digest(document)
        hash[:name].should == 'Kokindová Eleonóra'
      end
    end
    
    it "should parse 'Marta Vaľková' out of a document with the name 'Notársky úrad Bardejov - Marta Vaľková JUDr.'" do
      VCR.use_cassette('notari_15000') do
        extractor = Etl::NotarExtraction.new(15000, 1,15000)
        document = extractor.download(15000)
        hash = extractor.digest(document)
        hash[:name].should == 'Marta Vaľková'
      end
    end
    
    it "should parse 'Floriánová Ľubica' out of a document with the name 'Floriánová Ľubica JUDr.'" do
      VCR.use_cassette('notari_14963') do
        extractor = Etl::NotarExtraction.new(14963, 1,14963)
        document = extractor.download(14963)
        hash = extractor.digest(document)
        hash[:name].should == 'Floriánová Ľubica'
      end
    end

    it "should parse 'Korenková' out of a document with the name 'NU Mgr. Korenková'" do
      VCR.use_cassette('notari_13963') do
        extractor = Etl::NotarExtraction.new(13963, 1,13963)
        document = extractor.download(13963)
        hash = extractor.digest(document)
        hash[:name].should == 'Korenková'
      end
    end
    
    it 'should dump testing data' do
      VCR.use_cassette('notari_13537') do
        extractor = Etl::NotarExtraction.new(13537, 1,13537)
        document = extractor.download(13537)
        hash = extractor.digest(document)
        hash.should be_nil
      end
    end
    
    it "should parse 'Štefan Štefanko' out of a document with the name 'JUDr. Štefan Štefanko'" do
      VCR.use_cassette('notari_6140') do
        extractor = Etl::NotarExtraction.new(6140, 1,6140)
        document = extractor.download(6140)
        hash = extractor.digest(document)
        hash[:name].should == 'Štefan Štefanko'
      end
    end
    
    it "should parse 'Miloš Kaan' out of a document with the name 'Notársky úrad - JUDr.Miloš Kaan '" do
      VCR.use_cassette('notari_4829') do
        extractor = Etl::NotarExtraction.new(4829, 1,4829)
        document = extractor.download(4829)
        hash = extractor.digest(document)
        hash[:name].should == 'Miloš Kaan'
      end
    end
    
    it "should parse 'Zuzana Lutašová' out of a document with the name 'JUDr. Zuzana Lutašová'" do
      VCR.use_cassette('notari_4094') do
        extractor = Etl::NotarExtraction.new(4094, 1,4094)
        document = extractor.download(4094)
        hash = extractor.digest(document)
        hash[:name].should == 'Zuzana Lutašová'
      end
    end
    
    it "should parse 'Horváthová' out of a document with the name 'Notársky úrad JUDr. Horváthová'" do
      VCR.use_cassette('notari_3834') do
        extractor = Etl::NotarExtraction.new(3834, 1,3834)
        document = extractor.download(3834)
        hash = extractor.digest(document)
        hash[:name].should == 'Horváthová'
      end
    end
    
    it "should parse 'Soňa Šuvadová' out of a document with the name 'JUDr.- Soňa Šuvadová'" do
      VCR.use_cassette('notari_3534') do
        extractor = Etl::NotarExtraction.new(3534, 1,3534)
        document = extractor.download(3534)
        hash = extractor.digest(document)
        hash[:name].should == 'Soňa Šuvadová'
      end
    end
    
    it "should parse 'Tatiany Bradáčovej' out of a document with the name 'Notársky úrad JUDr. Tatiany Bradáčovej'" do
      VCR.use_cassette('notari_3070') do
        extractor = Etl::NotarExtraction.new(3070, 1,3070)
        document = extractor.download(3070)
        hash = extractor.digest(document)
        hash[:name].should == 'Tatiany Bradáčovej'
      end
    end
    
    it "should parse 'Ivona Žilíková' out of a document with the name 'Notársky úrad, Mgr. Ivona Žilíková'" do
      VCR.use_cassette('notari_1578') do
        extractor = Etl::NotarExtraction.new(1578, 1,1578)
        document = extractor.download(1578)
        hash = extractor.digest(document)
        hash[:name].should == 'Ivona Žilíková'
      end
    end
    
    it "should parse 'Telepčák Vladimír' out of a document with the name 'Telepčák, Vladimír, JUDr.'" do
      VCR.use_cassette('notari_1380') do
        extractor = Etl::NotarExtraction.new(1380, 1,1380)
        document = extractor.download(1380)
        hash = extractor.digest(document)
        hash[:name].should == 'Telepčák Vladimír'
      end
    end
    
    it "should parse 'Márie Kvasnovskej' out of a document with the name 'notárky Márie Kvasnovskej'" do
      VCR.use_cassette('notari_1241') do
        extractor = Etl::NotarExtraction.new(1241, 1,1241)
        document = extractor.download(1241)
        hash = extractor.digest(document)
        hash[:name].should == 'Márie Kvasnovskej'
      end
    end
    
    it "should parse 'Rybánska Vlasta' out of a document with the name 'Rybánska Vlasta JUDr.'" do
      VCR.use_cassette('notari_1255') do
        extractor = Etl::NotarExtraction.new(1255, 1,1255)
        document = extractor.download(1255)
        hash = extractor.digest(document)
        hash[:name].should == 'Rybánska Vlasta'
      end
    end
  end
  
  describe 'checking' do
    it 'should get a list of active documents' do
      VCR.use_cassette('notari_list') do
        Etl::NotarExtraction.get_active_docs.should == ["15424", "19151", "19419", "20000", "18867", "18842", "19915", "19484", "18711", "18606", "19324", "19946", "19951", "19847", "17639", "19499", "20033", "20048", "19906", "19514", "19136", "19600", "15495", "15299", "19938", "19942", "19988", "19296", "19962", "20081", "18700", "19660", "20042", "20029", "18497", "20028", "18499", "19680", "16847", "19650", "19552", "19622", "19961", "18796", "20019", "19008", "19604", "19106", "18996", "15039", "19851", "19759", "19456", "19273", "18438", "17585", "18511", "19700", "18091", "19811", "19753", "19370", "19320", "19893", "19231", "19973", "18983", "19932", "17446", "19884", "19960", "19754", "17699", "19766", "20036", "16183", "19402", "20089", "19256", "19997", "18821", "15162", "17332", "17083", "397", "16511", "18943", "18232", "18981", "19314", "16193", "19693", "19742", "19200", "19721", "19984", "19351", "19432", "5066", "18599", "19985", "19409", "19472", "19462", "18315", "19959", "19676", "17572", "19047", "15030", "20090", "15270", "16263", "20011", "19380", "17468", "19829", "19979", "19381", "17259", "18632", "17371", "18763", "19607", "18562", "19661", "18648", "20030", "20091", "4545", "19400", "19397", "16394", "19542", "19603", "20051", "19770", "4625", "16926", "19990", "19800", "20005", "17040", "19569", "19907", "18339", "19933", "19044", "19201", "19288", "19831", "19488", "19379", "20021", "20024", "20032", "19821", "19728", "19886", "19678", "18373", "19294", "18055", "14962", "17267", "19152", "19189", "20068", "19490", "19958", "19363", "19581", "19011", "18627", "19696", "17997", "15125", "19956", "19633", "19206", "17671", "19537", "18476", "16190", "17906", "19503", "19936", "19982", "18694", "19626", "19165", "19819", "19272", "15447", "18986", "17308", "20069", "19135", "19192", "19747", "17507", "17159", "18890", "19796", "19513", "18429", "19407", "19861", "19991", "13414", "17245", "18614", "18406", "17373", "19224", "19127", "18286", "19177", "19386", "18848", "19697", "19598", "16779", "19816", "19372", "20022", "19341", "18073", "19914", "18977", "17508", "20070", "3495", "19719", "20013", "11978", "19995", "15000", "1891", "18791", "435", "640", "18149", "7883", "3300", "13550", "19741", "19014", "19", "19481", "19520", "19974", "16529", "19216", "19822", "20037", "17800", "15148", "19643", "19450", "19954", "19945", "20041", "18057", "18607", "19702", "19568", "17260", "18103", "19710", "19535", "19114", "19628", "16196", "15602", "19095", "19809", "16681", "19529", "19290", "18936", "19550", "20078", "19992", "20035", "19998", "16100", "17808", "20088", "19802", "19904", "16632", "17258", "15047", "20056", "17456", "19646", "19304", "20072", "19124", "19554", "19493", "16651", "17003", "20059", "19509", "19539", "19889", "19310", "15637", "15355", "18639", "19278", "19841", "19921", "18875", "19842", "19479", "19864", "20071", "19940", "19756", "14804", "17609", "19725", "19144", "19577", "18800", "18224", "19392", "19996", "19587", "18544", "19631", "14998", "17309", "20080", "19782", "18191", "18236", "18764", "15856", "19801", "19349", "19916", "19765", "19180", "15040", "17914", "18897", "18930", "19717", "17317", "19957", "20038", "18961", "20052", "20001", "19536", "20002", "17764"]
      end
    end
    
    it 'should return a correctly formatted list url' do
      Etl::NotarExtraction.list_url(12345).should == URI.encode("http://www.notar.sk/Úvod/Notárskecentrálneregistre/Notárskeúrady.aspx?__EVENTTARGET=dnn$ctr729$ViewSimpleWrapper$SimpleWrapperControl_729$DataGrid1&__EVENTARGUMENT=Page$12345")
    end
    
    it 'should activate active docs' do
      Kernel::DsNotary.should_receive(:where).and_return(stub(update_all: true))
      Etl::NotarExtraction.stub(:get_active_docs).and_return(["1"])
      Etl::NotarExtraction.activate_docs
    end
  end
  
end
