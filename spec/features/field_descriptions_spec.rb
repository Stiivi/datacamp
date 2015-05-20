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

  it 'user is able to change category for field descriptions', js: true do
    main_category = Factory(:field_description_category, title: 'main')
    other_category = Factory(:field_description_category, title: 'other')

    dataset = Factory(:dataset_description, en_title: 'doctors', with_dataset: true)

    add_categories_to_dataset(dataset, ['main', 'other'])

    first_name_field = Factory(:field_description, en_title: 'first name', identifier: 'first_name', dataset_description: dataset)
    surname_field = Factory(:field_description, en_title: 'surname name', identifier: 'surname_name', dataset_description: dataset, field_description_category: main_category)
    street_field = Factory(:field_description, en_title: 'street', identifier: 'street', dataset_description: dataset, field_description_category: other_category)

    visit dataset_description_path(id: dataset, locale: :en)

    has_fields_in_category(['surname name'], main_category)
    has_fields_in_category(['street'], other_category)

    click_link 'Sort'
    move_field_to_category(first_name_field, main_category)
    move_field_to_category(street_field, main_category)
    click_link 'Finish sorting'

    visit dataset_description_path(id: dataset, locale: :en)

    has_fields_in_category(['first name', 'surname name', 'street'], main_category)
  end

  private

  def add_categories_to_dataset(dataset, category_names)
    visit edit_field_description_categories_dataset_description_path(id: dataset, locale: :en)
    category_names.each { |category_name| check category_name }
    click_button 'Save'
  end

  def move_field_to_category(field, category)
    drop_place = find("li#field_description_category_#{category.id} ul li:first-child")
    find("li#field_description_#{field.id} img.drag_arrow").drag_to(drop_place)
    sleep(0.5)
  end

  def has_fields_in_category(field_names, category)
    within("li#field_description_category_#{category.id}") do
      page.should have_content *field_names
    end
  end
end