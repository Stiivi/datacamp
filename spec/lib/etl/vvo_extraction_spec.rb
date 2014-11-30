# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Etl::VvoExtraction do
  
  before :each do
    @extractor = Etl::VvoExtraction.new(1, 2,2675)
    
    #for some reason this does is not included in the transaction and has to be cleaned manually
    Staging::StaProcurement.delete_all
  end
  
  it 'should successfully init an instance' do
    @extractor.start_id.should == 1
    @extractor.batch_limit.should == 2
    @extractor.id.should == 2675
  end
  
  it 'should download a document' do
    VCR.use_cassette('vvo_2675') do
      @extractor.download(2675).should_not be_nil
    end
  end
  
  it 'should return a correctly formatted document url' do
    @extractor.document_url(12345).should == "http://www.uvo.gov.sk/sk/evestnik/-/vestnik/12345"
  end
  
  it 'should return a configuration' do
    EtlConfiguration.create(:name => 'vvo_extraction')
    @extractor.config.should_not be_nil
  end
  
  it 'should update last processed id' do
    config = EtlConfiguration.create(:name => 'vvo_extraction', :last_processed_id => 1)
    @extractor.update_last_processed
    config.reload.last_processed_id.should == 2675
  end
  
  it 'should not update last processed id if its not larger than current value' do
    config = EtlConfiguration.create(:name => 'vvo_extraction', :last_processed_id => 2676)
    @extractor.update_last_processed
    config.reload.last_processed_id.should == 2676
  end
  
  it 'should save extracted information to the database' do
    VCR.use_cassette('vvo_185504') do
      config = EtlConfiguration.create(:name => 'vvo_extraction', :last_processed_id => 2669, :batch_limit => 5)
      config.clear_report!
      document = @extractor.download(185504)
      procurement_hash = @extractor.digest(document)
      @extractor.save(procurement_hash)
      Staging::StaProcurement.count.should == 1
    end
  end
  
  it 'should update the last processed id and schedule a new job if it is the batch limit and something was processed within that limit.' do
    EtlConfiguration.create(:name => 'vvo_extraction', :last_processed_id => 2672, :batch_limit => 5)
    Delayed::Job.stub(:enque)
    extractor = Etl::VvoExtraction.new(2670, 5,2675)
    Delayed::Job.should_receive(:enqueue).exactly(6).times
    extractor.after(nil)
  end
  
  it 'should update the start id if it hits the batch limit and there was nothing processed during current batch.' do
    config = EtlConfiguration.create(:name => 'vvo_extraction', :last_processed_id => 2669, :batch_limit => 5)
    Delayed::Job.stub(:enque)
    extractor = Etl::VvoExtraction.new(2670, 5,2675)
    Delayed::Job.should_not_receive(:enqueue)
    extractor.after(nil)
    config.reload.start_id.should == 2670
  end
  
  it 'should not save the same thing twice into the database' do
    VCR.use_cassette('vvo_185504') do
      config = EtlConfiguration.create(:name => 'vvo_extraction', :last_processed_id => 185503, :batch_limit => 5)
      config.clear_report!
      document = @extractor.download(185504)
      procurement_hash = @extractor.digest(document)
      @extractor.save(procurement_hash) and @extractor.save(procurement_hash)
      Staging::StaProcurement.count.should == 1
    end
  end
  
  it 'should have a perform method that downloads, parses and saves to the db' do
    VCR.use_cassette('vvo_185504') do
      config = EtlConfiguration.create(:name => 'vvo_extraction', :last_processed_id => 185503, :batch_limit => 5)
      config.clear_report!
      @extractor = Etl::VvoExtraction.new(1, 2,185504)
      @extractor.perform
      Staging::StaProcurement.count.should == 1
      config.reload.last_processed_id.should == 185504
    end
  end

  it 'should update the last_processed_id only when something was processed' do
    VCR.use_cassette('vvo_185506') do
      config = EtlConfiguration.create(:name => 'vvo_extraction', :last_processed_id => 185505, :batch_limit => 5)
      extractor = Etl::VvoExtraction.new(1, 2,185506)
      extractor.perform
      config.reload.last_processed_id.should == 185505
    end
  end

  describe 'parsing' do
    it 'should test and accept documents that have a V in the h2 header' do
      VCR.use_cassette('vvo_185504') do
        document = @extractor.download(185504)
        @extractor.is_acceptable?(document).should be_true
      end
    end

    it 'should test and not accept documents that do not have a V in the h2 header' do
      VCR.use_cassette('vvo_185506') do
        document = @extractor.download(185506)
        @extractor.is_acceptable?(document).should be_false
      end
    end

    it 'should get basic information from a document' do
      VCR.use_cassette('vvo_185504') do
        document = @extractor.download(185504)
        @extractor.basic_information(document).should == {:procurement_id=>"12683 - VST", :bulletin_id=>204, :year=>2012}
      end
    end

    it 'should get basic customer information from a document' do
      VCR.use_cassette('vvo_185504') do
        document = @extractor.download(185504)
        @extractor.customer_information(document).should == {:customer_name=>"Nemocnica s poliklinikou Považská Bystrica", :customer_ico=>"00610411"}
      end
    end

    it 'should get basic contract information from a document' do
      VCR.use_cassette('vvo_185504') do
        document = @extractor.download(185504)
        @extractor.contract_information(document).should == {:procurement_subject => "Vaky na odber darcovskej krvi a spracovanie krvných prípravkov."}
      end
    end

    it 'should get price even if it was not finalized' do
      VCR.use_cassette('vvo_185504') do
        document = @extractor.download(185504)
        @extractor.suppliers_information(document).should == {:suppliers=>[{:supplier_name=>"PHARMA GROUP,a.s.", :supplier_ico=>31320911.0, :is_price_part_of_range=>false, :price=>48933.72, :currency=>"EUR", :vat_included=>true}]}
      end
    end

    it 'should get price even if it was not finalized' do
      VCR.use_cassette('vvo_185583') do
        document = @extractor.download(185583)
        @extractor.suppliers_information(document).should == {:suppliers=>[{:supplier_name=>"MONTRÚR s.r.o.", :supplier_ico=>31657095.0, :is_price_part_of_range=>false, :price=>5400000.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"BMS BOJŇANSKÝ s.r.o.", :supplier_ico=>36546941.0, :is_price_part_of_range=>false, :price=>4400000.0, :currency=>"EUR", :vat_included=>false}]}
      end
    end

    it 'should get price even if it was not finalized' do
      VCR.use_cassette('vvo_191763') do
        document = @extractor.download(191763)
        @extractor.suppliers_information(document).should == {:suppliers=>[{:supplier_name=>"PRODEX spol. s.r.o.", :supplier_ico=>17314569.0, :is_price_part_of_range=>true, :price=>865866.0, :currency=>"EUR", :vat_included=>false}]}
      end
    end

    it 'should get price even if it was not finalized' do
      VCR.use_cassette('vvo_186450') do
        document = @extractor.download(186450)
        @extractor.suppliers_information(document).should == {:suppliers=>[{:supplier_name=>"DOXX Stravné lístky, spol. s r.o.", :supplier_ico=>36391000.0, :is_price_part_of_range=>false, :price=>1588134.401, :currency=>"EUR", :vat_included=>false}]}
      end
    end

    it 'should get price even if it was not finalized' do
      VCR.use_cassette('vvo_185892') do
        document = @extractor.download(185892)
        @extractor.suppliers_information(document).should == {:suppliers=>[{:supplier_name=>"Bundesdruckerei GmbH", :supplier_ico=>81274661.0, :is_price_part_of_range=>false, :price=>3509600.0, :currency=>"EUR", :vat_included=>false}]}
      end
    end


    it 'should get suppliers information from a document' do
      VCR.use_cassette('vvo_192396') do
        document = @extractor.download(192396)
        @extractor.suppliers_information(document).should == {:suppliers=>[{:supplier_name=>"SPODNIAK s.r.o.", :supplier_ico=>43877460.0, :is_price_part_of_range=>false, :price=>3000.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Štefan Kubáš", :supplier_ico=>46130250.0, :is_price_part_of_range=>false, :price=>3000.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Rudolf Olšiak ml.", :supplier_ico=>37106767.0, :is_price_part_of_range=>false, :price=>3000.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Milan Plavucha", :supplier_ico=>40145735.0, :is_price_part_of_range=>false, :price=>3000.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Miroslav Brijak", :supplier_ico=>40592600.0, :is_price_part_of_range=>false, :price=>3000.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Ján Šróba", :supplier_ico=>40587894.0, :is_price_part_of_range=>false, :price=>3000.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"PLENT, s.r.o.", :supplier_ico=>36007391.0, :is_price_part_of_range=>false, :price=>3000.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"SPODNIAK s.r.o.", :supplier_ico=>43877460.0, :is_price_part_of_range=>false, :price=>432860.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Rudolf Olšiak ml.", :supplier_ico=>37106767.0, :is_price_part_of_range=>false, :price=>432860.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"PLENT, s.r.o.", :supplier_ico=>36007391.0, :is_price_part_of_range=>false, :price=>432860.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Štefan Kubáš", :supplier_ico=>46130250.0, :is_price_part_of_range=>false, :price=>432860.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Miroslav Brijak", :supplier_ico=>40592600.0, :is_price_part_of_range=>false, :price=>432860.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Ján Šróba", :supplier_ico=>40587894.0, :is_price_part_of_range=>false, :price=>432860.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Milan Plavucha", :supplier_ico=>40145735.0, :is_price_part_of_range=>false, :price=>432860.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"SPODNIAK s.r.o.", :supplier_ico=>43877460.0, :is_price_part_of_range=>false, :price=>339000.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Rudolf Olšiak ml.", :supplier_ico=>37106767.0, :is_price_part_of_range=>false, :price=>339000.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Ján Šróba", :supplier_ico=>40587894.0, :is_price_part_of_range=>false, :price=>339000.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"PLENT, s.r.o.", :supplier_ico=>36007391.0, :is_price_part_of_range=>false, :price=>339000.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Štefan Kubáš", :supplier_ico=>46130250.0, :is_price_part_of_range=>false, :price=>339000.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Miroslav Brijak", :supplier_ico=>40592600.0, :is_price_part_of_range=>false, :price=>339000.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Milan Plavucha", :supplier_ico=>40145735.0, :is_price_part_of_range=>false, :price=>339000.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"SPODNIAK s.r.o.", :supplier_ico=>43877460.0, :is_price_part_of_range=>false, :price=>48427.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Miroslav Brijak", :supplier_ico=>40592600.0, :is_price_part_of_range=>false, :price=>48427.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Rudolf Olšiak ml.", :supplier_ico=>37106767.0, :is_price_part_of_range=>false, :price=>48427.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Milan Plavucha", :supplier_ico=>40145735.0, :is_price_part_of_range=>false, :price=>48427.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Ján Šróba", :supplier_ico=>40587894.0, :is_price_part_of_range=>false, :price=>48427.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Štefan Kubáš", :supplier_ico=>46130250.0, :is_price_part_of_range=>false, :price=>48427.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"PLENT, s.r.o.", :supplier_ico=>36007391.0, :is_price_part_of_range=>false, :price=>48427.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Rudolf Olšiak ml.", :supplier_ico=>37106767.0, :is_price_part_of_range=>false, :price=>19370.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Ján Šróba", :supplier_ico=>40587894.0, :is_price_part_of_range=>false, :price=>19370.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Milan Plavucha", :supplier_ico=>40145735.0, :is_price_part_of_range=>false, :price=>19370.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"SPODNIAK s.r.o.", :supplier_ico=>43877460.0, :is_price_part_of_range=>false, :price=>19370.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Štefan Kubáš", :supplier_ico=>46130250.0, :is_price_part_of_range=>false, :price=>19370.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"PLENT, s.r.o.", :supplier_ico=>36007391.0, :is_price_part_of_range=>false, :price=>19370.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Miroslav Brijak", :supplier_ico=>40592600.0, :is_price_part_of_range=>false, :price=>19370.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"SPODNIAK s.r.o.", :supplier_ico=>43877460.0, :is_price_part_of_range=>false, :price=>9690.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Rudolf Olšiak ml.", :supplier_ico=>37106767.0, :is_price_part_of_range=>false, :price=>9690.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Štefan Kubáš", :supplier_ico=>46130250.0, :is_price_part_of_range=>false, :price=>9690.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Ján Šróba", :supplier_ico=>40587894.0, :is_price_part_of_range=>false, :price=>9690.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Miroslav Brijak", :supplier_ico=>40592600.0, :is_price_part_of_range=>false, :price=>9690.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Milan Plavucha", :supplier_ico=>40145735.0, :is_price_part_of_range=>false, :price=>9690.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"PLENT, s.r.o.", :supplier_ico=>36007391.0, :is_price_part_of_range=>false, :price=>9690.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Rudolf Olšiak ml.", :supplier_ico=>37106767.0, :is_price_part_of_range=>false, :price=>29060.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Ján Šróba", :supplier_ico=>40587894.0, :is_price_part_of_range=>false, :price=>29060.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"SPODNIAK s.r.o.", :supplier_ico=>43877460.0, :is_price_part_of_range=>false, :price=>29060.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Štefan Kubáš", :supplier_ico=>46130250.0, :is_price_part_of_range=>false, :price=>29060.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Miroslav Brijak", :supplier_ico=>40592600.0, :is_price_part_of_range=>false, :price=>29060.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Milan Plavucha", :supplier_ico=>40145735.0, :is_price_part_of_range=>false, :price=>29060.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"PLENT, s.r.o.", :supplier_ico=>36007391.0, :is_price_part_of_range=>false, :price=>29060.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"SPODNIAK s.r.o.", :supplier_ico=>43877460.0, :is_price_part_of_range=>false, :price=>9690.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Rudolf Olšiak ml.", :supplier_ico=>37106767.0, :is_price_part_of_range=>false, :price=>9690.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Ján Šróba", :supplier_ico=>40587894.0, :is_price_part_of_range=>false, :price=>9690.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Milan Plavucha", :supplier_ico=>40145735.0, :is_price_part_of_range=>false, :price=>9690.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Štefan Kubáš", :supplier_ico=>46130250.0, :is_price_part_of_range=>false, :price=>9690.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Miroslav Brijak", :supplier_ico=>40592600.0, :is_price_part_of_range=>false, :price=>9690.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"PLENT, s.r.o.", :supplier_ico=>36007391.0, :is_price_part_of_range=>false, :price=>9690.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Rudolf Olšiak ml.", :supplier_ico=>37106767.0, :is_price_part_of_range=>false, :price=>29060.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"SPODNIAK s.r.o.", :supplier_ico=>43877460.0, :is_price_part_of_range=>false, :price=>29060.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Ján Šróba", :supplier_ico=>40587894.0, :is_price_part_of_range=>false, :price=>29060.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Miroslav Brijak", :supplier_ico=>40592600.0, :is_price_part_of_range=>false, :price=>29060.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Milan Plavucha", :supplier_ico=>40145735.0, :is_price_part_of_range=>false, :price=>29060.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"Štefan Kubáš", :supplier_ico=>46130250.0, :is_price_part_of_range=>false, :price=>29060.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"PLENT, s.r.o.", :supplier_ico=>36007391.0, :is_price_part_of_range=>false, :price=>29060.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"DR DREVO s.r.o.", :supplier_ico=>36023892.0, :is_price_part_of_range=>false, :price=>24210.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"SPODNIAK s.r.o.", :supplier_ico=>43877460.0, :is_price_part_of_range=>false, :price=>24210.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"PLENT, s.r.o.", :supplier_ico=>36007391.0, :is_price_part_of_range=>false, :price=>24210.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"DR DREVO s.r.o.", :supplier_ico=>36023892.0, :is_price_part_of_range=>false, :price=>24210.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"SPODNIAK s.r.o.", :supplier_ico=>43877460.0, :is_price_part_of_range=>false, :price=>24210.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"PLENT, s.r.o.", :supplier_ico=>36007391.0, :is_price_part_of_range=>false, :price=>24210.0, :currency=>"EUR", :vat_included=>false}]}
      end
    end
  end

end
