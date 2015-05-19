require 'spec_helper'

describe 'FieldDescriptions' do
  before(:each) do
    login_as(admin_user)
  end

  it 'user is able to add new field description to dataset description' do
    dataset = Factory(:dataset_description, en_title: 'doctors', with_dataset: true)

    visit dataset_description_path(id: dataset, locale: :en)
    click_link 'Add field description'

    click_button 'Save'
    page.should have_content 'can\'t be blank'

    fill_in 'field_description_en_title', with: 'first name'
    fill_in 'field_description_identifier', with: 'first_name'
    click_button 'Save'

    page.should have_content 'first_name'
  end

  it 'user is able to update field description' do
    dataset = Factory(:dataset_description, en_title: 'doctors', with_dataset: true)
    field_description = Factory(:field_description, en_title: 'First name', identifier: 'first_name', dataset_description: dataset)

    visit edit_dataset_description_field_description_path(dataset_description_id: dataset, id: field_description, locale: :en)

    fill_in 'field_description_identifier', with: ''
    click_button 'Save'
    page.should have_content 'can\'t be blank'

    fill_in 'field_description_en_title', with: 'given name'
    fill_in 'field_description_identifier', with: 'first_name'
    click_button 'Save'

    page.should have_content 'DatasetDescription was successfully updated'
    page.should have_content 'given name'
  end

  it 'user is possible, to edit identifier name in field description, not it raises error'

  it 'user is able to destroy field description' do
    dataset = Factory(:dataset_description, en_title: 'doctors', with_dataset: true)
    field_description = Factory(:field_description, en_title: 'First name', identifier: 'first_name', dataset_description: dataset)

    visit dataset_description_path(id: dataset, locale: :en)

    page.should have_content 'First name'

    within "li#field_description_#{field_description.id}" do
      click_link 'Delete'
    end

    page.should_not have_content 'First name'
  end
end