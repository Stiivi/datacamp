# coding: utf-8
require 'spec_helper'

describe 'Users' do
  let!(:miranda_user) { FactoryGirl.create(:user, login: 'miranda', is_super_user: false) }

  before(:each) do
    generate_sample_access_role_with_rights

    login_as(admin_user)
  end

  it 'user is able to see all users in system' do
    visit settings_users_path(locale: :en)

    page.should have_content 'miranda'
  end

  it 'user is able to download csv file of all users' do
    visit settings_users_path(locale: :en)

    click_link '(CSV ↓)'

    content_type.should be_csv
    page.should have_text 'miranda'
  end

  it 'user is able to create new user' do
    visit new_settings_user_path(locale: :en)

    fill_in 'user_login', with: 'andrej'
    fill_in 'user_email', with: 'andrej@gmail.com'
    fill_in 'user_password', with: 'very_secret'
    fill_in 'user_password_confirmation', with: 'very_secret'

    check 'User manager'
    check 'Grant rights'

    within('.action_buttons') do
      click_button 'Create User'
    end

    page.should have_content 'andrej'
  end

  it 'user is able to edit user' do
    visit edit_settings_user_path(id: miranda_user, locale: :en)

    fill_in 'user_login', with: 'andrej_4'

    within('.action_buttons') do
      click_button 'Update User'
    end

    page.should have_content 'andrej_4'
  end

  it 'user is able to destroy user' do
    visit settings_users_path(locale: :en)

    within("#user_#{miranda_user.id}") do
      click_link 'Delete'
    end

    page.should_not have_content 'miranda'
  end
end