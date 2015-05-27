require 'spec_helper'

describe 'Datasets' do

  let(:lists_category) { Factory(:category, title: 'lists') }

  let!(:quality_dataset) { Factory(:dataset_description, en_title: 'doctors', category: lists_category, is_active: true, with_dataset: true, bad_quality: false) }

  context 'anonymous user' do
    let!(:not_quality_dataset) { Factory(:dataset_description, en_title: 'students', category: lists_category, is_active: true, with_dataset: true, bad_quality: true) }
    let!(:not_active_dataset) { Factory(:dataset_description, en_title: 'schools', category: lists_category, is_active: false, with_dataset: true, bad_quality: true) }

    it 'is able to all available datasets' do
      visit datasets_path(locale: :en)

      page.should have_content 'lists'

      page_have_datasets_in_category(lists_category, ['doctors'])
      page.should_not have_content('schools')
    end

    it 'is able to display also datasets with bad quality' do
      visit datasets_path(locale: :en)

      click_link 'Show all datasets'

      page.should have_content 'lists'

      page_have_datasets_in_category(lists_category, ['doctors', 'students'])
      page.should_not have_content('schools')
    end

    it 'is able to see published records and visible columns in dataset' do
      Factory(:field_description, en_title: 'First name', identifier: 'first_name', dataset_description: quality_dataset)
      Factory(:field_description, en_title: 'Last name', identifier: 'last_name', dataset_description: quality_dataset, is_visible_in_detail: false)
      Factory(:field_description, en_title: 'Description', identifier: 'description', dataset_description: quality_dataset, is_visible_in_listing: false)

      record_1 = quality_dataset.dataset_record_class.create!(first_name: 'John', last_name: 'Smith', description: 'Young', record_status: 'published', quality_status: 'unclear')
      record_2 = quality_dataset.dataset_record_class.create!(first_name: 'Ann', last_name: 'Brutal', description: 'From city', record_status: 'loaded')

      visit datasets_path(locale: :en)

      click_link 'doctors'

      page.should have_content 'John', 'Smith'
      page.should_not have_content 'Ann', 'Brutal', 'Young', 'From city'

      within("#kernel_ds_doctor_#{record_1.id}") do
        click_link 'View'
      end

      page.should have_content 'John', 'Smith', 'Young', 'Unclear'
      page.should_not have_content 'Smith'

      # metadata
      page.should have_content 'published'
    end

    it 'is able to sort records by column' do
      Factory(:field_description, en_title: 'First name', identifier: 'first_name', dataset_description: quality_dataset)

      record_1 = quality_dataset.dataset_record_class.create!(first_name: 'John', record_status: 'published')
      record_2 = quality_dataset.dataset_record_class.create!(first_name: 'Ann', record_status: 'published')

      visit dataset_path(id: quality_dataset, locale: :en)

      record_1.first_name.should appear_before(record_2.first_name)

      click_link 'First name'

      record_2.first_name.should appear_before(record_1.first_name)

      click_link 'First name'

      record_1.first_name.should appear_before(record_2.first_name)
    end
  end

  context 'admin user' do
    before(:each) do
      generate_all_quality_status
      login_as(admin_user)
    end

    it 'is able to filder records', js: true do
      Factory(:field_description, en_title: 'First name', identifier: 'first_name', dataset_description: quality_dataset)

      quality_dataset.dataset_record_class.create!(first_name: 'John', record_status: 'published', quality_status: 'unclear')
      quality_dataset.dataset_record_class.create!(first_name: 'Ann', record_status: 'loaded', quality_status: 'ok')

      visit dataset_path(id: quality_dataset, locale: :en)

      page.should have_content 'John', 'Ann'

      within('.top_pagination') do
        select 'Loaded', from: 'filters_record_status'
      end

      page.should have_content 'Ann'
      page.should_not have_content 'John'

      within('.top_pagination') do
        select '- All -', from: 'filters_record_status'
      end
      sleep(0.5)

      within('.top_pagination') do
        select 'Unclear', from: 'filters_quality_status'
      end
      sleep(0.5)

      page.should have_content 'John'
      page.should_not have_content 'Ann'
    end

    it 'is able to update record status and quality status for multiple rows at once', js: true do
      Factory(:field_description, en_title: 'First name', identifier: 'first_name', dataset_description: quality_dataset)

      record_1 = quality_dataset.dataset_record_class.create!(first_name: 'John', record_status: 'published', quality_status: 'unclear')
      record_2 = quality_dataset.dataset_record_class.create!(first_name: 'Ann', record_status: 'loaded', quality_status: 'ok')
      record_3 = quality_dataset.dataset_record_class.create!(first_name: 'Peter', record_status: 'new', quality_status: 'absent')

      visit dataset_path(id: quality_dataset, locale: :en)

      check "check_kernel_ds_doctor_#{record_1._record_id}"
      check "check_kernel_ds_doctor_#{record_3._record_id}"
      select 'Suspended', from: 'status'
      sleep(0.5)

      record_1.reload.record_status.should eq 'suspended'
      record_2.reload.record_status.should eq 'loaded'
      record_3.reload.record_status.should eq 'suspended'

      check "check_kernel_ds_doctor_#{record_1._record_id}"
      check "check_kernel_ds_doctor_#{record_2._record_id}"
      select 'Duplicate', from: 'quality'
      sleep(0.5)

      record_1.reload.quality_status.should eq 'duplicate'
      record_2.reload.quality_status.should eq 'duplicate'
      record_3.reload.quality_status.should eq 'absent'

      check "check_kernel_ds_doctor_#{record_1._record_id}"
      select 'All filtered records', from: 'selection'
      select 'New', from: 'status'
      sleep(0.5)

      record_1.reload.record_status.should eq 'new'
      record_2.reload.record_status.should eq 'new'
      record_3.reload.record_status.should eq 'new'

      click_link 'select_all'
      select 'OK', from: 'quality'
      sleep(0.5)

      record_1.reload.quality_status.should eq 'ok'
      record_2.reload.quality_status.should eq 'ok'
      record_3.reload.quality_status.should eq 'ok'
    end

    it 'is able to use batch update to set the same value for multiple records at once', js: true do
      Factory(:field_description, en_title: 'First name', identifier: 'first_name', dataset_description: quality_dataset)
      Factory(:field_description, en_title: 'Last name', identifier: 'last_name', dataset_description: quality_dataset)

      record_1 = quality_dataset.dataset_record_class.create!(first_name: 'John', last_name: 'Smith')
      record_2 = quality_dataset.dataset_record_class.create!(first_name: 'Ann', last_name: 'Hamster')
      record_3 = quality_dataset.dataset_record_class.create!(first_name: 'Peter', last_name: 'House')

      visit dataset_path(id: quality_dataset, locale: :en)

      check "check_kernel_ds_doctor_#{record_1._record_id}"
      check "check_kernel_ds_doctor_#{record_3._record_id}"
      click_link 'Batch edit'
      sleep(0.5)

      page.should have_content 'Editing 2 selected records'

      fill_in 'value_last_name', with: 'Bob'
      click_button 'Update all'

      page.should have_content '2 records were successfuly updated'

      record_1.reload.first_name.should eq 'John'
      record_1.reload.last_name.should eq 'Bob'

      record_2.reload.first_name.should eq 'Ann'
      record_2.reload.last_name.should eq 'Hamster'

      record_3.reload.first_name.should eq 'Peter'
      record_3.reload.last_name.should eq 'Bob'
    end

    it 'should not fail when user make batch edit with no new value'
  end

  private

  def page_have_datasets_in_category(category, dateset_names)
    within(".dataset_category_#{category.id}") do
      page.should have_content *dateset_names
    end
  end
end
