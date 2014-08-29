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
        Etl::NotarExtraction.get_active_docs.should == ["23193", "20457", "20765", "22124", "22871", "21219", "20359", "22287", "20122", "22345", "22344", "22291", "22274", "17639", "22099", "20951", "23129", "23319", "21187", "22144", "23087", "15495", "15299", "23309", "21546", "21097", "22599", "22405", "22802", "22843", "22830", "22829", "19680", "16847", "19650", "20391", "22899", "20444", "18796", "23272", "19008", "20304", "22711", "20328", "22720", "22185", "22996", "22341", "21243", "23278", "22222", "22804", "19700", "20499", "23335", "22967", "23338", "23230", "20393", "23276", "21722", "21489", "17446", "23300", "22946", "22519", "21945", "23348", "23038", "20879", "23227", "22059", "22738", "23233", "18821", "22718", "17332", "22246", "397", "22970", "23040", "21004", "23352", "21714", "22290", "22715", "22534", "20196", "23251", "20997", "21455", "22736", "23342", "22122", "23351", "23220", "23318", "23301", "21499", "22844", "23185", "23259", "22947", "21975", "15030", "21275", "22729", "22279", "21791", "23279", "22369", "22766", "20467", "21535", "22384", "17371", "22666", "19607", "21843", "23075", "22123", "22012", "22973", "4545", "21639", "22712", "20882", "23028", "23219", "21896", "23210", "23206", "4625", "21228", "22553", "20005", "22724", "21974", "21406", "21861", "21059", "21480", "22960", "23158", "21715", "22264", "21421", "22995", "23015", "23325", "21925", "19728", "22733", "23154", "20465", "22822", "22437", "14962", "23146", "21736", "20068", "23310", "23311", "22934", "22022", "21529", "23302", "23225", "17997", "15125", "22924", "22725", "21943", "22923", "17906", "22722", "22511", "22758", "20830", "18694", "22306", "21523", "20728", "19272", "22105", "18986", "22142", "22682", "22152", "21655", "20392", "23095", "23323", "18890", "22950", "23270", "22584", "21800", "22317", "19991", "13414", "21327", "22678", "20741", "23012", "23317", "19224", "22761", "18286", "21505", "21869", "22482", "22870", "22193", "21217", "23076", "21781", "20022", "19341", "18073", "23139", "23018", "21839", "22626", "22614", "3495", "21184", "11978", "22990", "20120", "1891", "18791", "435", "22997", "7883", "13550", "23345", "20987", "22205", "19", "19481", "23136", "22755", "20109", "22759", "20126", "21085", "23294", "23324", "22726", "22313", "22710", "22513", "23188", "21998", "22265", "21101", "18607", "22708", "23328", "23346", "22765", "22113", "22010", "23332", "23151", "16681", "22262", "22030", "20711", "22227", "22663", "21970", "19992", "22632", "22493", "20202", "22301", "19802", "23307", "23291", "23228", "15047", "23336", "22667", "22056", "23253", "23196", "23238", "22148", "22966", "22981", "21479", "23074", "23191", "23274", "23286", "20645", "23068", "22125", "22610", "19921", "23194", "22770", "22938", "22427", "23019", "21157", "23013", "22877", "22734", "22596", "22514", "20992", "22181", "23229", "18224", "19392", "21149", "23244", "23083", "18544", "23305", "20684", "20806", "17309", "23258", "23096", "23186", "22150", "22320", "20230", "22359", "22266", "19916", "22101", "21753", "17914", "23037", "23268", "23213", "22607", "23123", "22398", "20300", "22472", "23339", "20898", "22102", "23137"]
      end
    end
    
    it 'should return a correctly formatted list url' do
      Etl::NotarExtraction.list_url.should == URI.encode("http://www.notar.sk/Úvod/Notárskecentrálneregistre/Notárskeúrady.aspx")
    end
  end
end
