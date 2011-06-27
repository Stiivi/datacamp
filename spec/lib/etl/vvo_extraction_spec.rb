require 'spec_helper'

describe Etl::VvoExtraction do
  
  it 'should successfully init an instance' do
    extractor = Etl::VvoExtraction.new(1, 2,2675)
    extractor.start_id.should == 1
    extractor.batch_limit.should == 2
    extractor.id.should == 2675
  end
  
end