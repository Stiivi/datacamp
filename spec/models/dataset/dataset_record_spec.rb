require 'spec_helper'

describe Dataset::DatasetRecord do
  describe 'derived_fields' do
    it 'are included in default scope' do
      description = FactoryGirl.create(:dataset_description, en_title: 'doctors', with_dataset: true)
      FactoryGirl.create(:field_description, identifier: 'name', dataset_description: description)
      FactoryGirl.create(:field_description, identifier: 'ending', dataset_description: description, is_derived: true, derived_value: "CONCAT(`name`, ' - hello')")

      description.reload_dataset_model
      description.dataset_model.create!(name: 'Peter')
      description.dataset_model.first.ending.should eq 'Peter - hello'
      description.dataset_model.all.first.ending.should eq 'Peter - hello'
    end
  end
end