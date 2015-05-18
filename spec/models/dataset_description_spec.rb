require 'spec_helper'

describe DatasetDescription do
  before :each do
    @dataset_description = Factory(:dataset_description, identifier: 'something')
  end

  it 'should fetch changes' do
    @dataset_description.stub(:dataset_record_class).and_return(stub(name: 'name'))
    updates = [stub('update')]
    Dataset::DcUpdate.should_receive(:find_all_by_updatable_type).with('name').and_return(updates)
    @dataset_description.fetch_changes.should == updates
  end

  describe "log creating a dataset" do

    it 'should report new dataset creation to the changes table' do
      Change.should have(1).records
      Change.first.change_details.count.should == 5
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
      Change.destroy_all
    end

    it 'should record a change to a dataset record' do
      Change.should_receive(:create)
      DatasetDescription.new.destroy
    end
  end

  describe 'log changes to a dataset record' do
    it 'should record a change to a dataset record' do
      DatasetDescription.stub(:create)
      Change.should_receive(:create)
      DatasetDescription.new.send(:log_changes)
    end
  end

end
