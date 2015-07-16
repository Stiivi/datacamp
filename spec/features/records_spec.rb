require 'spec_helper'

describe 'Records' do
  before(:each) do
    login_as(admin_user)
  end

  let!(:doctors_dataset) { FactoryGirl.create(:dataset_description, en_title: 'doctors', with_dataset: true) }
  let!(:first_name_field) { FactoryGirl.create(:field_description, en_title: 'First name', identifier: 'first_name', dataset_description: doctors_dataset) }

  it 'user is able to add new record' do
    visit new_dataset_record_path(dataset_id: doctors_dataset, locale: :en)

    fill_in 'kernel_ds_doctor_first_name', with: 'John'
    click_button 'Create Ds doctor'

    doctors_dataset.dataset_model.should have(1).record
    page.should have_content 'John'
  end

  it 'user is able to edit record' do
    record_1 = doctors_dataset.dataset_model.create!(first_name: 'John')

    visit dataset_record_path(dataset_id: doctors_dataset, id: record_1, locale: :en)
    click_link 'Edit'

    fill_in 'kernel_ds_doctor_first_name', with: 'Math'
    click_button 'Update Ds doctor'

    record_1.reload.first_name.should eq('Math')
  end

  it 'user is able to delete record' do
    record_1 = doctors_dataset.dataset_model.create!(first_name: 'John')

    visit dataset_record_path(dataset_id: doctors_dataset, id: record_1, locale: :en)
    click_link 'Delete'

    doctors_dataset.dataset_model.should have(0).records
  end
end