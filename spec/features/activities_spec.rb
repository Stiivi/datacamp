require 'spec_helper'

describe 'Activities' do
  before(:each) do
    login_as(admin_user)
  end

  it 'user is able to see what changes happend in the system' do
    Factory(:dataset_description, en_title: 'students', with_dataset: true)

    visit activities_path(locale: :en)

    page.should have_content 'dataset_create', 'dataset_create'

    within("#change_#{Change.first.id}") do
      click_link 'View'
    end

    page.should have_content 'dataset_create', 'dataset_create'
  end
end