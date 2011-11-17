require 'spec_helper'

describe DatasetDescription do
  before :each do
    @dataset_description = Factory(:dataset_description)
  end
  
  describe "log creating a dataset" do
    
    it 'should report new dataset creation to the changes table' do
      Change.should have(1).records
      Change.first.change_details.count.should == 4
    end

    it 'should save information about a creation of a dataset to the changes table' do
      change = Change.first

      change.change_type.should == Change::DATASET_CREATE
      change.dataset_description.should == @dataset_description
    end
  end
  
  describe 'log deletion to dataset' do
    
    before :each do
      Change.destroy_all
      @dataset_description.destroy
    end
    it 'should record deletion of a dataset' do
      Change.should have(1).records
    end
    
    it 'should save information about a deletion of a dataset to the changes table' do
      change = Change.first
      
      change.change_type.should == Change::DATASET_DESTROY
      change.dataset_description_cache['identifier'].should == @dataset_description.identifier
    end
  end
  
  describe 'log changes to a dataset' do
    before :each do
      Change.destroy_all
    end
    it 'should record a change to a dataset' do
      @dataset_description.update_attributes(identifier: 'new_identifier', is_active: false)
      Change.first.change_details.count.should == 2
    end
    
    it 'should record all changes correctly' do
      @dataset_description.update_attributes(identifier: 'new_identifier')
      change_detail = Change.first.change_details.first
      
      change_detail[:changed_field].should == 'identifier'
      change_detail[:old_value].should == 'something'
      change_detail[:new_value].should == 'new_identifier'
      Change.first.change_type.should == Change::DATASET_UPDATE
    end
  end
  
  describe 'log deletion of a dataset record' do
    before :each do
      @dataset_description.update_attributes(identifier: 'advokats')
      @dataset_description.dataset.dataset_record_class.create
      Change.destroy_all
    end
    
    it 'should record a change to a dataset record' do
      @dataset_description.dataset.dataset_record_class.first.destroy
      Change.should have(1).records
    end
  end
  
  describe 'log changes to a dataset record' do
    before :each do
      @dataset_description.update_attributes(identifier: 'advokats')
      Change.destroy_all
    end
    
    it 'should record a change to a dataset record' do
      @dataset_description.dataset.dataset_record_class.create
      Change.should have(1).records
    end
  end
  
end