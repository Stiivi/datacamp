require 'spec_helper'

describe 'Activities' do
  before(:each) do
    login_as(admin_user)
  end

  it 'user is able to see what changes happend in the system' do
    FactoryGirl.create(:dataset_description, en_title: 'students', with_dataset: true)

    visit activities_path(locale: :en)

    page_should_have_content_with 'dataset_create', 'students'

    within("#change_#{Change.first.id}") do
      click_link 'View'
    end

    page_should_have_content_with 'dataset_create', 'students'
  end
end