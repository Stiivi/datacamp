require 'spec_helper'

describe 'Datasets' do

  let(:lists_category) { Factory(:category, title: 'lists') }

  context 'anonymous user' do
    let!(:quality_dataset) { Factory(:dataset_description, en_title: 'doctors', category: lists_category, is_active: true, with_dataset: true, bad_quality: false) }
    let!(:not_quality_dataset) { Factory(:dataset_description, en_title: 'students', category: lists_category, is_active: true, with_dataset: true, bad_quality: true) }
    let!(:not_active_dataset) { Factory(:dataset_description, en_title: 'schools', category: lists_category, is_active: false, with_dataset: true, bad_quality: true) }

    it 'user is able to all available datasets' do
      visit datasets_path(locale: :en)

      page.should have_content 'lists'

      page_have_datasets_in_category(lists_category, ['doctors'])
      page.should_not have_content('schools')
    end

    it 'user is able to display also datasets with bad quality' do
      visit datasets_path(locale: :en)

      click_link 'Show all datasets'

      page.should have_content 'lists'

      page_have_datasets_in_category(lists_category, ['doctors', 'students'])
      page.should_not have_content('schools')
    end

    it 'user is able to see published records in dataset' do
      Factory(:field_description, en_title: 'First name', identifier: 'first_name', dataset_description: quality_dataset)
      Factory(:field_description, en_title: 'Last name', identifier: 'last_name', dataset_description: quality_dataset)

      record_1 = quality_dataset.dataset_record_class.create!(first_name: 'John', last_name: 'Smith', record_status: 'published', quality_status: 'unclear')
      record_2 = quality_dataset.dataset_record_class.create!(first_name: 'Ann', last_name: 'Brutal', record_status: 'loaded')

      visit datasets_path(locale: :en)

      click_link 'doctors'

      page.should have_content 'John', 'Smith'
      page.should_not have_content 'Ann', 'Brutal'

      within("#kernel_ds_doctor_#{record_1.id}") do
        click_link 'View'
      end

      page.should have_content 'John', 'Smith', 'Unclear'
    end
  end



  private

  def page_have_datasets_in_category(category, dateset_names)
    within(".dataset_category_#{category.id}") do
      page.should have_content *dateset_names
    end
  end
end
