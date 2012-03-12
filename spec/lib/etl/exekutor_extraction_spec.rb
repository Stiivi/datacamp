# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Etl::ExekutorExtraction do
  before :each do
    @extractor = Etl::ExekutorExtraction.new
    
    #for some reason this does is not included in the transaction and has to be cleaned manually
    Staging::StaExecutor.delete_all
  end
  
  it 'should have a perform method that downloads, parses and saves to the db' do
    VCR.use_cassette('executors') do
      @extractor.perform
      Staging::StaExecutor.count.should == 299
    end
  end
  
  describe 'parsing' do
    it 'should test and accept valid documents' do
      VCR.use_cassette('executors') do
        document = @extractor.download
        @extractor.is_acceptable?(document).should be_true
      end
    end
    
    it 'should get information from a document' do
      VCR.use_cassette('executors') do
        extractor = Etl::ExekutorExtraction.new
        document = extractor.download
        executors = extractor.digest(document)
        executors.length.should == 299
        executors.first.should == {:name=>"JUDr. Ádám Atila", :street => 'Čajakova 5', :zip => '040 01', :city => 'Košice', :telephone=>"+421 55/6424552", :fax=>"+421 55/6424552", :email=>"atila.adam@ske.sk"}
        executors.last.should == {:name=>"JUDr. Žužová Lucia", :street => 'ul.Okružná 5', :zip => '071 01', :city => 'Michalovce', :telephone=>"056 6882891,-2", :fax=>"056 6882893", :email=>"lucia.zuzova@ske.sk"}
      end
    end
    
  end
end