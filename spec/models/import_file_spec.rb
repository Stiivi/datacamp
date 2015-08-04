require 'spec_helper'

describe ImportFile do
  
  def mock_import_file(stubs={})
    @mock_import_file ||= mock_model(ImportFile, stubs).as_null_object
  end
  
  before :each do
    @import_file = ImportFile.new
  end
  
  describe 'initialization' do
    it 'should initialize key variables to default values on init' do
      ImportFile.new.col_separator.should == ','
    end
  end
  
  describe 'validation' do
    it 'should have attachment errors blank if file exists and is parsable' do
      @import_file.stub(csv_file: stub(is_valid?: true))
      @import_file.attachment_csv_errors.should be_nil
    end
    it 'should add errors for an csv file' do
      @import_file.stub(csv_file: stub(is_valid?: false))
      @import_file.attachment_csv_errors.should_not be_nil
    end
  end
  
  describe 'read csv' do
    it 'should find mappings for the columns in the file to a dataset' do
      @import_file.stub(dataset_description_field_descriptions: [stub(identifier: 'field2', id: 25), stub(identifier: 'field1', id: 15)], header: ['field1', 'field2'])
      @import_file.mapping_from_header.should == [15, 25]
    end
    
    it 'should read the header line' do
      header = ['field1', 'field2']
      @import_file.stub(file_template: 'csv', csv_file: stub(header: header))
      @import_file.header.should == header
    end
    
    it 'should read a sample line' do
      sample = ['field1', 'field2']
      @import_file.stub(file_template: 'csv', csv_file: stub(sample: sample))
      @import_file.sample.should == sample
    end
  end
  
end