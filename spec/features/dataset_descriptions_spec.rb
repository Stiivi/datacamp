require 'spec_helper'

describe 'DatasetDescriptions' do
  before(:each) do
    login_as(admin_user)
  end

  let!(:lists_category) { Factory(:dataset_category, title: 'lists') }

  it 'user can see dataset grouped by categories' do
    Factory(:dataset_description, en_title: 'lawyers', is_active: true, category: lists_category)
    Factory(:dataset_description, en_title: 'doctors', is_active: false, category: lists_category)
    Factory(:dataset_description, en_title: 'set with no category', is_active: false, category: nil)

    visit dataset_descriptions_path(locale: :en)

    page.should have_content 'lists'
    page.should have_content 'inactive'
    has_datasets_in_category(['lawyers', 'doctors'], lists_category)

    page.should have_content 'set with no category'
  end

  it 'user is able to create new dataset' do
    visit new_dataset_description_path(locale: :en)

    click_button 'Save'

    page.should have_content 'can\'t be blank'

    fill_in 'dataset_description_en_title', with: 'companies'
    fill_in 'dataset_description_sk_title', with: 'firmy'
    fill_in 'dataset_description_identifier', with: 'companies'
    select 'lists', from: 'dataset_description_category_id'

    click_button 'Save'

    page.should have_content 'Dataset created'

    visit dataset_descriptions_path(locale: :en)
    has_datasets_in_category(['companies'], lists_category)
  end

  it 'user is able to create new dataset with new category' do
    visit new_dataset_description_path(locale: :en)

    click_button 'Save'

    page.should have_content 'can\'t be blank'

    fill_in 'dataset_description_en_title', with: 'companies'
    fill_in 'dataset_description_sk_title', with: 'firmy'
    fill_in 'dataset_description_identifier', with: 'companies'
    fill_in 'dataset_description_category', with: 'public documents'

    click_button 'Save'

    page.should have_content 'Dataset created'

    visit dataset_descriptions_path(locale: :en)
    has_datasets_in_category(['companies'], DatasetCategory.find_by_title!('public documents'))
  end

  it 'user is able to edit dataset' do
    dataset_description = Factory(:dataset_description, en_title: 'doctors', is_active: true, category: lists_category)
    visit edit_dataset_description_path(id: dataset_description, locale: :en)

    fill_in 'dataset_description_en_title', with: ''

    click_button 'Save'
    page.should have_content 'can\'t be blank'

    fill_in 'dataset_description_en_title', with: 'court doctors'
    click_button 'Save'

    page.should have_content 'DatasetDescription was successfully updated'
  end

  it 'user is able to destroy dataset' do
    dataset_description = Factory(:dataset_description, en_title: 'doctors', is_active: true, category: lists_category)

    visit dataset_descriptions_path(locale: :en)

    within("#dataset_description_#{dataset_description.id}") do
      click_link 'Delete'
    end

    visit dataset_descriptions_path(locale: :en)
    does_not_have_datasets_in_category('doctors', lists_category)
  end

  private

  def has_datasets_in_category(dataset_names, category)
    within("li#dataset_category_#{category.id}") do
      page.should have_content *dataset_names
    end
  end

  def does_not_have_datasets_in_category(dataset_names, category)
    within("li#dataset_category_#{category.id}") do
      page.should_not have_content *dataset_names
    end
  end
end