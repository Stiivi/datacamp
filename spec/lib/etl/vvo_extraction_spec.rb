# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Etl::VvoExtraction do
  
  before :all do
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
    @extractor.document_url(12345).should == "http://www.e-vestnik.sk/EVestnik/Detail/12345"
  end
  
  it 'should return a configuration' do
    EtlConfiguration.create(:name => 'vvo_extraction')
    @extractor.config.should_not be_nil
  end
  
  it 'should update last processed id' do
    extractor = Etl::VvoExtraction.new(1, 2,2675)
    config = EtlConfiguration.create(:name => 'vvo_extraction', :last_processed_id => 1)
    extractor.update_last_processed
    config.reload.last_processed_id.should == 2675
  end
  
  it 'should not update last processed id if its not larger than current value' do
    extractor = Etl::VvoExtraction.new(1, 2,2675)
    config = EtlConfiguration.create(:name => 'vvo_extraction', :last_processed_id => 2676)
    extractor.update_last_processed
    config.reload.last_processed_id.should == 2676
  end
  
  it 'should save extracted information to the database' do
    VCR.use_cassette('vvo_2675') do
      document = @extractor.download(2675)
      procurement_hash = @extractor.basic_information(document).merge(@extractor.customer_information(document)).merge(@extractor.suppliers_information(document))
      @extractor.save(procurement_hash)
      Staging::StaProcurement.count.should == 45
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
    VCR.use_cassette('vvo_2675') do
      document = @extractor.download(2675)
      procurement_hash = @extractor.basic_information(document).merge(@extractor.customer_information(document)).merge(@extractor.suppliers_information(document))
      @extractor.save(procurement_hash) and @extractor.save(procurement_hash)
      Staging::StaProcurement.count.should == 45
    end
  end
  
  it 'should have a perform method that downloads, parses and saves to the db' do
    VCR.use_cassette('vvo_2675') do
      config = EtlConfiguration.create(:name => 'vvo_extraction', :last_processed_id => 2669, :batch_limit => 5)
      extractor = Etl::VvoExtraction.new(1, 2,2675)
      extractor.perform
      Staging::StaProcurement.count.should == 45
      config.reload.last_processed_id.should == 2675
    end
  end
  
  it 'should update the last_processed_id only when something was processed' do
    VCR.use_cassette('vvo_2692') do
      config = EtlConfiguration.create(:name => 'vvo_extraction', :last_processed_id => 2669, :batch_limit => 5)
      extractor = Etl::VvoExtraction.new(1, 2,2692)
      extractor.perform
      config.reload.last_processed_id.should == 2669
    end
  end
  
  describe 'parsing' do
    it 'should test and accept documents that have a V in the h2 header' do
      VCR.use_cassette('vvo_2675') do
        document = @extractor.download(2675)
        @extractor.is_acceptable?(document).should be_true
      end
    end

    it 'should test and not accept documents that do not have a V in the h2 header' do
      VCR.use_cassette('vvo_2692') do
        document = @extractor.download(2692)
        @extractor.is_acceptable?(document).should be_false
      end
    end

    it 'should get basic information from a document' do
      VCR.use_cassette('vvo_2675') do
        document = @extractor.download(2675)
        @extractor.basic_information(document).should == {:procurement_id => '00035 - VST', :bulletin_id => 4, :year => 2009}
      end
    end

    it 'should get basic customer information from a document' do
      VCR.use_cassette('vvo_2675') do
        document = @extractor.download(2675)
        @extractor.customer_information(document).should == {:customer_name => "Fakultná nemocnica Trnava",:customer_ico => 610381}
      end
    end

    it 'should get basic contract information from a document' do
      VCR.use_cassette('vvo_2675') do
        document = @extractor.download(2675)
        @extractor.contract_information(document).should == {:procurement_subject => "Lieky a liečivá pre potreby Nemocničnej lekárne Fakultnej nemocnice Trnava."}
      end
    end

    it 'should get suppliers information from a document' do
      VCR.use_cassette('vvo_2675') do
        document = @extractor.download(2675)
        @extractor.suppliers_information(document).should == {:suppliers=>[{:supplier_name=>"UNIPHARMA PRIEVIDZA, 1. slovenská lekárnická akciová spoločnosť", :supplier_ico=>31625657.0, :is_price_part_of_range=>false, :price=>22050.91, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED-ART, spol. s r. o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>13944.57, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"UNIPHARMA PRIEVIDZA, 1. slovenská lekárnická akciová spoločnosť", :supplier_ico=>31625657.0, :is_price_part_of_range=>false, :price=>17788.24, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MARTEK MEDICAL SK, a. s.", :supplier_ico=>31708030.0, :is_price_part_of_range=>false, :price=>48521.6, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED - ART, spol. s r. o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>13496.21, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"UNIPHARMA PRIEVIDZA, 1. slovenská lekárnická akciová spoločnosť", :supplier_ico=>31625657.0, :is_price_part_of_range=>false, :price=>30214.48, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MARTEK MEDICAL, SK a. s.", :supplier_ico=>31708030.0, :is_price_part_of_range=>false, :price=>99202.25, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MARTEK MEDICAL, SK a. s.", :supplier_ico=>31708030.0, :is_price_part_of_range=>false, :price=>23624.11, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"IMUNA PHARM, a. s.", :supplier_ico=>36473685.0, :is_price_part_of_range=>false, :price=>64329.81, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"INTRAVENA, s. r. o.", :supplier_ico=>31717802.0, :is_price_part_of_range=>false, :price=>134721.67, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"UNIPHARMA PRIEVIDZA, 1. slovenská lekárnická akciová spoločnosť", :supplier_ico=>31625657.0, :is_price_part_of_range=>false, :price=>37627.09, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MARTEK MEDICAL SK, a. s.", :supplier_ico=>31708030.0, :is_price_part_of_range=>false, :price=>51644.76, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED-ART, spol. s r. o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>19038.11, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"UNIPHARMA PRIEVIDZA, 1. slovenská lekárnická akciová spoločnosť", :supplier_ico=>31625657.0, :is_price_part_of_range=>false, :price=>35888.2, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED-ART, spol. s r. o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>32816.43, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED-ART, spol. s r. o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>17749.34, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"UNIPHARMA PRIEVIDZA, 1. slovenská lekárnická akciová spoločnosť", :supplier_ico=>31625657.0, :is_price_part_of_range=>false, :price=>116435.2, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED-ART, spol. s r. o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>18030.66, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MARTEK MEDICAL SK, a. s.", :supplier_ico=>31708030.0, :is_price_part_of_range=>false, :price=>39778.6, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"UNIPHARMA PRIEVIDZA, 1. slovenská lekárnická akciová spoločnosť", :supplier_ico=>31625657.0, :is_price_part_of_range=>false, :price=>18954.15, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED-ART, spol. s r. o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>33074.02, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MARTEK MEDICAL SK, a. s.", :supplier_ico=>31708030.0, :is_price_part_of_range=>false, :price=>30011.12, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED-ART, spol. s r. o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>63694.12, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED-ART, spol. s r. o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>16868.14, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MARTEK MEDICAL SK a. s.", :supplier_ico=>31708030.0, :is_price_part_of_range=>false, :price=>40025.89, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MARTEK MEDICAL SK, a. s.", :supplier_ico=>31708030.0, :is_price_part_of_range=>false, :price=>31945.83, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"UNIPHARMA PRIEVIDZA, 1. slovenská lekárnická akciová spoločnosť", :supplier_ico=>31625657.0, :is_price_part_of_range=>false, :price=>35667.32, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED - ART, spol. s r.o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>20822.41, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"UNIPHARMA PRIEVIDZA 1. slovenská lekárnická akciová spoločnosť", :supplier_ico=>31625657.0, :is_price_part_of_range=>false, :price=>35645.0, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED - ART, spol. s r.o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>7439.66, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED - ART, spol. s r.o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>176668.36, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MARTEK MEDICAL SK a. s.", :supplier_ico=>31708030.0, :is_price_part_of_range=>false, :price=>42665.94, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MARTEK MEDICAL SK a. s.", :supplier_ico=>31708030.0, :is_price_part_of_range=>false, :price=>47065.24, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED - ART, spol. s r.o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>16127.73, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MARTEK MEDICAL SK a. s.", :supplier_ico=>31708030.0, :is_price_part_of_range=>false, :price=>230770.76, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED - ART, spol. s r.o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>16489.15, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"COOPEX M spol. s.r.o.", :supplier_ico=>31385117.0, :is_price_part_of_range=>false, :price=>24756.02, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MARTEK MEDICAL SK a. s.", :supplier_ico=>31708030.0, :is_price_part_of_range=>false, :price=>31758.93, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED - ART, spol. s r.o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>20865.19, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"UNIPHARMA PRIEVIDZA 1. slovenská lekárnická akciová spoločnosť", :supplier_ico=>31625657.0, :is_price_part_of_range=>false, :price=>30188.43, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"INTRAVENA s.r.o.", :supplier_ico=>31717802.0, :is_price_part_of_range=>false, :price=>22115.56, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MARTEK MEDICAL SK a. s.", :supplier_ico=>31708030.0, :is_price_part_of_range=>false, :price=>173569.67, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED - ART, spol. s r.o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>23409.5, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED - ART, spol. s r.o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>128046.34, :currency=>"EUR", :vat_included=>false}, {:supplier_name=>"MED - ART, spol. s r.o.", :supplier_ico=>34113924.0, :is_price_part_of_range=>false, :price=>28171.67, :currency=>"EUR", :vat_included=>false}]}
      end
    end
  end
  
  
end