require 'spec_helper'

describe 'Imports' do
  before(:each) do
    login_as(admin_user)
  end

  after(:each) do
    Dir.glob("#{Rails.root}/files/*_example.csv").each do |filepath|
      File.delete(filepath)
    end
  end

  let(:name_csv_file_path) { Rails.root.join('spec', 'files', 'names_example.csv') }

  it 'user is able to import csv file to prepared dataset' do
    dataset = Factory(:dataset_description, en_title: 'doctors', with_dataset: true)

    Factory(:field_description, en_title: 'First name', identifier: 'first_name', dataset_description: dataset)
    Factory(:field_description, en_title: 'Last name', identifier: 'last_name', dataset_description: dataset)

    visit new_import_file_path(locale: :en)

    select 'doctors', from: 'import_file_dataset_description_id'
    attach_file 'File', name_csv_file_path
    click_button 'Continue'

    click_button 'Import'

    page.should have_content 'loaded successfuly'

    click_link 'Go to dataset'

    page.should have_content 'jan', 'velky', 'matus', 'maly', 'dominik', 'hello'

    dataset.dataset_record_class.should have(3).records
  end
end