require 'spec_helper'

describe 'DatasetCategories' do
  before(:each) do
    login_as(admin_user)
  end

  it 'user can see categories in dataset description screen' do
    Factory(:category, title: 'documents')
    Factory(:category, title: 'persons')

    visit dataset_descriptions_path(locale: :en)

    page.should have_content 'documents'
    page.should have_content 'persons'
  end

  # not sure if this test is needed, but it is in the system, so I wrote a test for it
  it 'user can see categories in category listing' do
    Factory(:category, title: 'documents')
    Factory(:category, title: 'persons')

    visit categories_path(locale: :en)

    page.should have_content 'documents'
    page.should have_content 'persons'
  end

  it 'user is able to create new category' do
    visit new_category_path(locale: :en)

    click_button 'Save'
    page.should have_content 'can\'t be blank'

    fill_in 'dataset_category_en_title', with: 'documents'
    fill_in 'dataset_category_sk_title', with: 'documents'
    click_button 'Save'

    page.should have_content 'documents'
  end

  it 'user is able to create new category from dataset description page', js: true do
    visit dataset_descriptions_path(locale: :en)

    click_link 'New category'

    fill_in 'dataset_category_en_title', with: 'documents'
    click_button 'Submit'

    page.should have_content 'documents'
  end

  it 'user is able to edit category' do
    category = Factory(:category, title: 'documents')

    visit edit_dataset_category_path(id: category, locale: :en)

    fill_in 'dataset_category_en_title', with: 'important documents'
    click_button 'Save'
    page.should have_content 'important documents'
  end

  it 'user should see if he tries to update category to invalid'

  it 'user is able to inline edit category', js: true do
    category = Factory(:category, title: 'documents')

    visit dataset_descriptions_path(locale: :en)

    within("li#dataset_category_#{category.id}") do
      click_link 'Edit'
    end

    fill_in 'dataset_category[title]', with: 'important documents'
    within("li#dataset_category_#{category.id}") do
      click_link 'Edit'
    end

    page.should have_content 'important documents'
  end

  it 'user is able to delete category' do
    category = Factory(:category, title: 'documents')

    visit dataset_descriptions_path(locale: :en)

    within("li#dataset_category_#{category.id}") do
      click_link 'Delete'
    end

    page.should_not have_content 'important documents'
  end
end