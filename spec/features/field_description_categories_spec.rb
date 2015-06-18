require 'spec_helper'

describe 'FieldDescriptionCategories' do
  before(:each) do
    login_as(admin_user)
  end

  it 'user can see field description categories' do
    FactoryGirl.create(:field_description_category, title: 'main attributes')

    visit field_description_categories_path(locale: :en)

    page.should have_content 'main attributes'
  end

  it 'user should not be allow to store invalid record both in create and update'

  it 'user is able to create new category' do
    visit new_field_description_category_path(locale: :en)

    fill_in 'field_description_category_en_title', with: 'for import'
    fill_in 'field_description_category_sk_title', with: 'for import'
    click_button 'Save'

    page.should have_content 'for import'
  end

  it 'user is able to edit category' do
    category = FactoryGirl.create(:field_description_category, title: 'main attributes')

    visit field_description_categories_path(locale: :en)

    within("#field_description_category_#{category.id}") do
      click_link 'Edit'
    end

    fill_in 'field_description_category_en_title', with: 'for us and for import'
    click_button 'Save'
    page.should have_content 'for us and for import'
  end

  it 'user is able to delete category' do
    category = FactoryGirl.create(:field_description_category, title: 'main attributes')

    visit field_description_categories_path(locale: :en)

    within("#field_description_category_#{category.id}") do
      click_link 'Delete'
    end

    page.should_not have_content 'main attributes'
  end
end