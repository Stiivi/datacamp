require 'spec_helper'

describe ImportFile do
  
  describe 'initialization' do
    it 'should initialize key variables to default values on init' do
      ImportFile.new.col_separator.should == ','
    end
  end
  
end