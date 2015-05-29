require 'spec_helper'

describe 'Searches' do
  let!(:list_category) { Factory(:category, title: 'educations') }
  let!(:student_dataset) { Factory(:dataset_description, en_title: 'students', is_active: true, with_dataset: true, category: list_category) }
  let!(:student_name_field) { Factory(:field_description, identifier: 'name', dataset_description: student_dataset) }
  let!(:student_address_field) { Factory(:field_description, identifier: 'address', dataset_description: student_dataset, is_visible_in_search: false) }
  let!(:peter_student_record) { student_dataset.dataset_record_class.create!(name: 'Peter', address: 'Town at home', record_status: 'published') }
  let!(:lukas_student_record) { student_dataset.dataset_record_class.create!(name: 'Lukas', address: 'Village', record_status: 'published') }
  let!(:tom_student_record) { student_dataset.dataset_record_class.create!(name: 'Tom', address: 'Street', record_status: 'published') }

  let!(:school_dataset) { Factory(:dataset_description, en_title: 'Schools', is_active: true, with_dataset: true, category: list_category) }
  let!(:school_name_field) { Factory(:field_description, identifier: 'name', dataset_description: school_dataset) }
  let!(:grammar_school_record) { school_dataset.dataset_record_class.create!(name: 'Grammar', record_status: 'published') }

  before(:each) do
    prepare_sphinx_search
  end

  it 'user is able to use fulltext search on page' do
    visit root_path(locale: :en)

    fill_in 'query_string', with: 'Peter'
    click_button 'query_submit'

    page.should have_content 'educations', 'Peter'
    page.should_not have_content 'Town at home'

    click_link 'More results'

    page.should have_content 'Peter'
    page.should_not have_content 'Lukas', 'Tom'
  end

  it 'user is informed if requested query is not found' do
    visit root_path(locale: :en)

    fill_in 'query_string', with: 'Alice'
    click_button 'query_submit'

    page.should_not have_content 'Alice'
  end
end