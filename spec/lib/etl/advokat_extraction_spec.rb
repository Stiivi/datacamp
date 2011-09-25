# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Etl::AdvokatExtraction do
  
  before :each do
    @extractor = Etl::AdvokatExtraction.new("https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/list/formular/rows/4690/link/display/event")
    
    #for some reason this does is not included in the transaction and has to be cleaned manually
    Staging::StaAdvokat.delete_all
  end
  
  it 'should download a document' do
    VCR.use_cassette('advokat_4690') do
      @extractor.download.should_not be_nil
    end
  end
  
  describe 'parsing' do
    
    it 'should test and accept valid documents' do
      VCR.use_cassette('advokat_4690') do
        document = @extractor.download
        @extractor.is_acceptable?(document).should be_true
      end
    end
    
    it 'should test and not accept invalid documents' do
      VCR.use_cassette('advokat_1') do
        extractor = Etl::AdvokatExtraction.new("https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/list/formular/rows/1/link/display/event")
        document = extractor.download
        extractor.is_acceptable?(document).should be_false
      end
    end
    
    it 'should get information from a document' do
      VCR.use_cassette('advokat_4690') do
        document = @extractor.download
        advokat = @extractor.digest(document)
        advokat.should == {:name=>"ABELOVSKÁ Iveta JUDr.", :avokat_type=>"Advokát", :street=>"Hlučínska 1", :city=>"BRATISLAVA 3", :zip=>"831 03", :phone=>"02/44634927", :fax=>"02/44454498", :cell_phone=>"", :languages=>"rusky", :email=>"kancelaria@abelovskasulva.sk", :website=>nil, :url => "https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/list/formular/rows/4690/link/display/event", :trainees_attributes => []}
      end
    end
    
    it 'should get information from a document' do
      VCR.use_cassette('advokat_295627') do
        extractor = Etl::AdvokatExtraction.new("https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/list/formular/rows/295627/link/display/event")
        document = extractor.download
        advokat = extractor.digest(document)
        advokat.should == {:name=>"ADAMČÍK Andrej Mgr.", :avokat_type=>"Advokát", :street=>"Sedlárska 1", :city=>"Bratislava 1", :zip=>"811 01", :phone=>"02/3219 1153", :fax=>"02/3214 4888", :cell_phone=>"0917/611153", :languages=>"anglicky", :email=>"andrej.adamcik@hillbridges.com", :website=>nil, :url => "https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/list/formular/rows/295627/link/display/event", :trainees_attributes => []}
      end
    end
    
    it 'should get information from a document' do
      VCR.use_cassette('advokat_19288') do
        extractor = Etl::AdvokatExtraction.new("https://www.sak.sk/blox/cms/sk/sak/adv/stop/proxy/list/formular/rows/19288/link/display/event", 'https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/link/display/formular/button/close/event', 'JSESSIONID=821AEC404DE28C7C364C9EBFAE075F49', 'https://www.sak.sk/blox/cms/sk/sak/adv/stop/proxy/list/formular/picker/event/page/10')
        document = extractor.download
        advokat = extractor.digest(document)
        advokat.should == {:name=>"BALAŽOVIČ Dušan JUDr.", :avokat_type=>"Advokát", :street=>"M.R.Štefánika 53", :city=>"NOVÉ ZÁMKY", :zip=>"940 01", :phone=>"", :fax=>"", :cell_phone=>"", :languages=>"", :email=>"", :website=>nil, :url => "https://www.sak.sk/blox/cms/sk/sak/adv/stop/proxy/list/formular/rows/19288/link/display/event", :trainees_attributes => []}
      end
    end
    
    it 'should get information from a document' do
      VCR.use_cassette('advokat_170603') do
        extractor = Etl::AdvokatExtraction.new("https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/list/formular/rows/170603/link/display/event", 'https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/link/display/formular/button/close/event', 'JSESSIONID=821AEC404DE28C7C364C9EBFAE075F49', 'https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/list/formular/picker/event/page/10')
        document = extractor.download
        advokat = extractor.digest(document)
        advokat.should == {:name=>"ADAMOVSKÝ Jozef JUDr.", :avokat_type=>"Advokát", :street=>"Čingovská 5", :city=>"Košice", :zip=>"040 12", :phone=>"", :fax=>"", :cell_phone=>"0949/369699", :languages=>"anglicky", :email=>"adamovsky@vialegis.sk", :website=>"/blox/adv/www.vialegis.sk", :url => "https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/list/formular/rows/170603/link/display/event", :trainees_attributes => []}
      end
    end
    
    it 'should get information from a document' do
      VCR.use_cassette('advokat_4515') do
        extractor = Etl::AdvokatExtraction.new("https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/list/formular/rows/4515/link/display/event", 'blox/cms/sk/sak/adv/vyhladanie/proxy/link/display/formular/button/close/event', 'JSESSIONID=821AEC404DE28C7C364C9EBFAE075F49', 'https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/list/formular/picker/event/page/0')
        document = extractor.download
        advokat = extractor.digest(document)
        advokat.should == {:name=>"ADAMČÍK Rudolf JUDr.", :avokat_type=>"Advokát", :street=>"Liptovská 2/A, P.O. BOX 67", :city=>"BRATISLAVA 2", :zip=>"820 05", :phone=>"02/53413792, 53412855", :fax=>"02/53413793", :cell_phone=>"", :languages=>"nemecky, rusky", :email=>"office@ada-ap.sk", :website=>nil, :url=>"https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/list/formular/rows/4515/link/display/event", :trainees_attributes=>[{:first_name=>"Čuraj", :last_name=>"Lukáš", :title=>"Mgr."}, {:first_name=>"Štiak", :last_name=>"Peter", :title=>"MUDr.Mgr."}]}
      end
    end
    
  end
  
  it 'should have a perform method that downloads, parses and saves to the db' do
    VCR.use_cassette('advokat_4690') do
      @extractor.perform
      Staging::StaAdvokat.count.should == 1
    end
  end
  
end