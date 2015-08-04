require 'spec_helper'

describe 'DatasetStates' do
  before(:each) do
    login_as(admin_user)
  end

  let(:dataset) { FactoryGirl.create(:dataset_description, en_title: 'doctors', with_dataset: true) }

  it 'user can see which columns are described and which are not described' do
    visit dataset_description_datastore_states_path(dataset_description_id: dataset, locale: :en)

    page.should have_content 'There are 1 columns in the dataset table that have no description'
    page.should have_content '_record_id'
    page.should have_content 'There are 0 dataset fields that have no columns in the dataset table'
  end

  it 'user can add missing description' do
    dataset.dataset_schema_manager.add_column('hello', 'string')

    visit dataset_description_datastore_states_path(dataset_description_id: dataset, locale: :en)

    within('#column_hello') do
      click_link 'Add'
    end

    dataset.field_descriptions.count.should eq 1
  end

  it 'user can add missing table column' do
    FactoryGirl.create(:field_description, identifier: 'hello', dataset_description: dataset)

    dataset.dataset_schema_manager.remove_column('hello')

    visit dataset_description_datastore_states_path(dataset_description_id: dataset, locale: :en)

    within('#column_hello') do
      click_link 'Add'
    end

    dataset.dataset_schema_manager.has_column?('hello').should eq true
  end
end