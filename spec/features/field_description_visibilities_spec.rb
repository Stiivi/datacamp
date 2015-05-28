require 'spec_helper'

describe 'FieldDescriptionVisibilities' do
  before(:each) do
    login_as(admin_user)
  end

  it 'uses is able to set up different visibilities for each filed description' do
    dataset =  Factory(:dataset_description, en_title: 'doctors', with_dataset: true)
    first_name_field = Factory(:field_description, en_title: 'First name', identifier: 'first_name', dataset_description: dataset)
    last_name_field = Factory(:field_description, en_title: 'Last name', identifier: 'last_name', dataset_description: dataset)
    school_field = Factory(:field_description, en_title: 'School', identifier: 'school', dataset_description: dataset)
    home_field = Factory(:field_description, en_title: 'Home', identifier: 'home', dataset_description: dataset)
    work_field = Factory(:field_description, en_title: 'Work', identifier: 'work', dataset_description: dataset)

    visit visibility_dataset_description_path(id: dataset, locale: :en)

    set_visible_flag_to('first_name', 'listing', false)
    set_visible_flag_to('last_name', 'search', false)
    set_visible_flag_to('school', 'detail', false)
    set_visible_flag_to('home', 'export', false)
    set_visible_flag_to('work', 'relation', false)

    within('.top_buttons') do
      click_button 'Save changes'
    end

    first_name_field.reload.is_visible_in_listing.should eq false
    last_name_field.reload.is_visible_in_search.should eq false
    school_field.reload.is_visible_in_detail.should eq false
    home_field.reload.is_visible_in_export.should eq false
    work_field.reload.is_visible_in_relation.should eq false

    visit visibility_dataset_description_path(id: dataset, locale: :en)

    set_visible_flag_to('first_name', 'listing', true)
    set_visible_flag_to('last_name', 'search', true)
    set_visible_flag_to('school', 'detail', true)
    set_visible_flag_to('home', 'export', true)
    set_visible_flag_to('work', 'relation', true)

    within('.top_buttons') do
      click_button 'Save changes'
    end

    first_name_field.reload.is_visible_in_listing.should eq true
    last_name_field.reload.is_visible_in_search.should eq true
    school_field.reload.is_visible_in_detail.should eq true
    home_field.reload.is_visible_in_export.should eq true
    work_field.reload.is_visible_in_relation.should eq true
  end

  private

  def set_visible_flag_to(field, visible_part, value)
    index_mapping = {
        'first_name' => '0',
        'last_name' => '1',
        'school' => '2',
        'home' => '3',
        'work' => '4',
    }.fetch(field) { raise "cannot map field '#{field}' to index" }

    checkbox_id = "dataset_description_field_descriptions_attributes_#{index_mapping}_is_visible_in_#{visible_part}"

    if value
      check checkbox_id
    else
      uncheck checkbox_id
    end
  end
end
