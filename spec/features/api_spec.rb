require 'spec_helper'

describe 'Api' do
  let!(:student_dataset) { FactoryGirl.create(:dataset_description, en_title: 'students', is_active: true, api_access_level: Api::REGULAR, with_dataset: true) }
  let!(:student_name_field) { FactoryGirl.create(:field_description, identifier: 'name', dataset_description: student_dataset) }
  let!(:peter_student_record) { student_dataset.dataset_record_class.create!(name: 'Peter', record_status: 'published') }

  let!(:school_dataset) { FactoryGirl.create(:dataset_description, en_title: 'Schools', is_active: true, api_access_level: Api::REGULAR, with_dataset: true) }
  let!(:school_name_field) { FactoryGirl.create(:field_description, identifier: 'name', dataset_description: school_dataset) }
  let!(:grammar_school_record) { school_dataset.dataset_record_class.create!(name: 'Grammar', record_status: 'published') }

  context 'registered user' do
    before(:each) do
      login_as(admin_user)
    end

    it 'is able to download dataset records in csv', use_dump: true do
      export_dump_for_dataset(student_dataset)

      visit dataset_path(id: student_dataset, locale: :en)

      click_link 'dataset_records_in_csv'
      content_type.should be_csv
      page.should have_text 'Peter'
    end

    it 'is able to download dataset description in xml' do
      visit dataset_path(id: student_dataset, locale: :en)

      click_link 'dataset_description_in_xml'

      content_type.should be_xml
      page_should_have_content_with 'students', 'name'
    end

    it 'is able to download dataset relations xml' do
      set_up_relation(student_dataset, school_dataset)

      peter_student_record.ds_schools << grammar_school_record
      peter_student_record.save!

      visit dataset_path(id: student_dataset, locale: :en)

      click_link 'dataset_relations_xml'
      content_type.should be_xml
      page_should_have_content_with 'Kernel::DsStudent', 'Kernel::DsSchool'
    end

    it 'is able to download changes in records' do
      peter_student_record.update_attributes(name: 'Daniel', quality_status: 'ok')

      visit dataset_path(id: student_dataset, locale: :en)

      click_link 'dataset_changes_in_xml'
      content_type.should be_xml
      page_should_have_content_with 'Peter', 'Daniel'
    end

    it 'is able to regenerate api key' do
      visit account_path(locale: :en)

      click_link 'Create new API key'

      admin_user.api_keys.should have(2).records
    end
  end

  context 'user with restricted api level' do
    before(:each) do
      FactoryGirl.create(:user, api_access_level: Api::RESTRICTED)

      login_as(FactoryGirl.create(:user))
    end

    it 'is not able to download dataset records in csv', use_dump: true do
      export_dump_for_dataset(student_dataset)

      visit dataset_path(id: student_dataset, locale: :en)

      click_link 'dataset_records_in_csv'

      status_code.should eq 401
      page.should have_content 'You do not have sufficient privileges'
    end
  end
end