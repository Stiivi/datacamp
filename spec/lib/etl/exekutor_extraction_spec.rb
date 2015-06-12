# -*- encoding : utf-8 -*-
require 'spec_helper'

class Kernel::DsExecutor; end

describe Etl::ExekutorExtraction do
  before :each do
    @extractor = Etl::ExekutorExtraction.new
  end
  
  it 'should have a perform method that downloads, parses and saves to the db' do
    VCR.use_cassette('etl/executor_extraction/executors') do
      @extractor.should_receive(:save)
      @extractor.perform
    end
  end
  
  describe 'parsing' do
    it 'should test and accept valid documents' do
      VCR.use_cassette('etl/executor_extraction/executors') do
        document = @extractor.download
        @extractor.is_acceptable?(document).should be_true
      end
    end
    
    it 'should get information from a document' do
      VCR.use_cassette('etl/executor_extraction/executors') do
        extractor = Etl::ExekutorExtraction.new
        document = extractor.download
        executors = extractor.digest(document)
        executors.length.should be > 300
        executors.first.should == {:name=>"JUDr. Ádám Atila", :street => 'Čajakova 5', :zip => '04001', :city => 'Košice', :telephone=>"+421 55/6424552", :fax=>"+421 55/6424552", :email=>"atila.adam@ske.sk"}
        executors.last.should == {:name=>"JUDr. Žabková Žofia", :street => 'Námestie Matice Slovenskej 6', :zip => '96501', :city => 'Žiar nad Hronom', :telephone=>"0948/011 261", :fax=>"-", :email=>"zofia.zabkova@ske.sk"}
        executor = executors.find{ |executor| executor[:name] == "JUDr. Stodolová Soňa" }
        executor.should == {:name=>"JUDr. Stodolová Soňa", :street=>"Kmeťková 25", :zip=>"94901", :city=>"Nitra", :telephone=>"037 6514444", :fax=>"037 6514444", :email=>"sona.stodolova@ske.sk"}
      end
    end
    
  end
end
