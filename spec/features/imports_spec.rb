# coding: utf-8
require 'spec_helper'

describe 'Imports' do
  before(:each) do
    login_as(admin_user)
  end

  # TODO: set up folder for uploading in test environment and clear this folder in each test
  after(:each) do
    Dir.glob("#{Rails.root}/files/*_example.csv").each do |filepath|
      File.delete(filepath)
    end
  end

  let(:name_csv_file_path) { Rails.root.join('spec', 'files', 'names_example.csv') }

  let(:doctors_dataset) { FactoryGirl.create(:dataset_description, en_title: 'doctors', with_dataset: true) }

  it 'user is able to import csv file to prepared dataset' do
    prepare_name_fields(doctors_dataset)

    fill_in_import_file_to_dataset(doctors_dataset, name_csv_file_path)

    click_button 'Import'

    page.should have_content 'loaded successfuly'

    click_link 'Go to dataset'

    page_should_have_content_with 'ján', 'veľký', 'matúš', 'malý', 'dominik', 'pekný'

    doctors_dataset.dataset_record_class.should have(3).records
  end

  it 'user is able to delete imported records from current import' do
    prepare_name_fields(doctors_dataset)

    doctors_dataset.dataset_record_class.create!(record_status: 'new', first_name: 'jozef', last_name: 'zelený')

    fill_in_import_file_to_dataset(doctors_dataset, name_csv_file_path)

    # set up incorrect mapping
    select 'Last name', from: 'column_0'
    select 'First name', from: 'column_1'

    click_button 'Import'

    page.should have_content 'loaded successfuly'

    doctors_dataset.dataset_record_class.should have(4).records

    doctors_dataset.dataset_record_class.last.first_name.should eq 'pekný'

    click_link 'Delete imported records'

    click_link 'Go to dataset'

    page_should_have_content_with 'jozef', 'zelený'

    doctors_dataset.dataset_record_class.should have(1).records
  end

  private

  def prepare_name_fields(dataset)
    FactoryGirl.create(:field_description, en_title: 'First name', identifier: 'first_name', dataset_description: dataset)
    FactoryGirl.create(:field_description, en_title: 'Last name', identifier: 'last_name', dataset_description: dataset)
  end

  def fill_in_import_file_to_dataset(dataset, file)
    visit new_import_file_path(locale: :en)

    select dataset.identifier, from: 'import_file_dataset_description_id'
    attach_file 'File', file
    click_button 'Continue'
  end
end