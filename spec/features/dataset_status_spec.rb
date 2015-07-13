require 'spec_helper'

describe 'DatasetStatus' do
  before(:each) do
    login_as(admin_user)
  end

  let(:dataset) { FactoryGirl.create(:dataset_description, en_title: 'doctors', with_dataset: true) }

  it 'user can see which columns are described and which are not described' do
    visit datastore_status_dataset_description_path(id: dataset, locale: :en)

    page.should have_content 'There are 1 columns in the dataset table that have no description'
    page.should have_content '_record_id'
    page.should have_content 'There are 0 dataset fields that have no columns in the dataset table'
  end
end