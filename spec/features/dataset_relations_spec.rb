require 'spec_helper'

describe 'DatasetRelations' do
  before(:each) do
    login_as(admin_user)
  end

  let!(:students) { Factory(:dataset_description, en_title: 'Students', with_dataset: true) }
  let!(:schools) { Factory(:dataset_description, en_title: 'Schools', with_dataset: true) }


  it 'is possible to manage relationship between dataset', js: true do
    visit relations_dataset_description_path(id: students, locale: :en)

    click_button '+'
    select 'Schools'
    click_button 'Save relations'

    students.relations.should have(1).record

    visit relations_dataset_description_path(id: students, locale: :en)
    click_button '-'
    click_button 'Save relations'

    students.relations.should have(0).record
  end

  it 'is possible to possible to map records from relation datasets', js: true do
    Factory(:field_description, dataset_description: students, identifier: 'name', is_visible_in_relation: true)
    student_record = students.dataset_record_class.create!(name: 'Filip')

    Factory(:field_description, dataset_description: schools, identifier: 'name', is_visible_in_relation: true)
    Factory(:field_description, dataset_description: schools, identifier: 'street', is_visible_in_relation: false)
    school_record = schools.dataset_record_class.create!(name: 'Gramar', street: 'Bratislava')

    students.relationship_dataset_descriptions << schools
    students.save!

    visit dataset_record_path(dataset_id: students, id: student_record, locale: :en)

    click_link 'Add'
    fill_in 'related_id', with: school_record._record_id.to_s
    click_button 'Save changes'

    page.should have_content 'Gramar'
    page.should_not have_content 'Bratislava'
  end

  it 'is possible to see relation in both sides when relationship is bi-directional' do
    students.relationship_dataset_descriptions << schools
    students.save!
    students.reload_dataset

    schools.relationship_dataset_descriptions << students
    schools.save!
    schools.reload_dataset

    Factory(:field_description, dataset_description: students, identifier: 'name', is_visible_in_relation: true)
    Factory(:field_description, dataset_description: schools, identifier: 'name', is_visible_in_relation: true)

    student_record = students.dataset_record_class.create!(name: 'Filip')
    school_record = schools.dataset_record_class.create!(name: 'Gramar')

    student_record.ds_schools << school_record
    student_record.save!

    visit dataset_record_path(dataset_id: students, id: student_record, locale: :en)
    page.should have_content 'Gramar'

    visit dataset_record_path(dataset_id: schools, id: school_record, locale: :en)
    page.should have_content 'Filip'
  end
end