require 'spec_helper'

describe 'DatasetRelations' do
  before(:each) do
    login_as(admin_user)
  end

  let!(:students) { FactoryGirl.create(:dataset_description, en_title: 'Students', with_dataset: true) }
  let!(:schools) { FactoryGirl.create(:dataset_description, en_title: 'Schools', with_dataset: true) }

  it 'is possible to manage relationship between dataset', js: true do
    visit dataset_description_relations_path(dataset_description_id: students, locale: :en)

    click_button '+'
    select 'Schools'
    click_button 'Save relations'

    students.relations.should have(1).record

    visit dataset_description_relations_path(dataset_description_id: students, locale: :en)
    click_button '-'
    click_button 'Save relations'

    students.relations.should have(0).record
  end

  it 'is possible to possible to map records from relation datasets', js: true do
    FactoryGirl.create(:field_description, dataset_description: students, identifier: 'name', is_visible_in_relation: true)
    student_record = students.dataset_model.create!(name: 'Filip')

    FactoryGirl.create(:field_description, dataset_description: schools, identifier: 'name', is_visible_in_relation: true)
    FactoryGirl.create(:field_description, dataset_description: schools, identifier: 'street', is_visible_in_relation: false)
    school_record = schools.dataset_model.create!(name: 'Grammar', street: 'Bratislava')

    set_up_relation(students, schools)

    visit dataset_record_path(dataset_id: students, id: student_record, locale: :en)

    click_link 'Add'
    fill_in 'related_id', with: school_record._record_id.to_s
    click_button 'Save changes'

    page.should have_content 'Grammar'
    page.should_not have_content 'Bratislava'
  end

  it 'is possible to see relation in both sides when relationship is bi-directional' do
    set_up_relation(students, schools)
    set_up_relation(schools, students)

    FactoryGirl.create(:field_description, dataset_description: students, identifier: 'name', is_visible_in_relation: true)
    FactoryGirl.create(:field_description, dataset_description: schools, identifier: 'name', is_visible_in_relation: true)

    student_record = students.dataset_model.create!(name: 'Filip')
    school_record = schools.dataset_model.create!(name: 'Grammar')

    student_record.ds_schools << school_record
    student_record.save!

    visit dataset_record_path(dataset_id: students, id: student_record, locale: :en)
    page.should have_content 'Grammar'

    visit dataset_record_path(dataset_id: schools, id: school_record, locale: :en)
    page.should have_content 'Filip'
  end

  it 'is possible to remove mapping from record', js: true do
    set_up_relation(students, schools)
    set_up_relation(schools, students)

    FactoryGirl.create(:field_description, dataset_description: students, identifier: 'name', is_visible_in_relation: true)
    FactoryGirl.create(:field_description, dataset_description: schools, identifier: 'name', is_visible_in_relation: true)

    student_record = students.dataset_model.create!(name: 'Filip')
    school_record = schools.dataset_model.create!(name: 'Grammar')

    student_record.ds_schools << school_record
    student_record.save!

    visit dataset_record_path(dataset_id: students, id: student_record, locale: :en)

    within("#related_kernel_ds_school_#{school_record._record_id}") do
      click_link 'Delete'
    end

    page.should have_content 'Relation deleted'
    student_record.reload.ds_schools.should eq []
  end
end