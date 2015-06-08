require 'spec_helper'

describe 'UserProfile' do
  let!(:user) { FactoryGirl.create(:user, login: 'test', password: 'secret', email: 'my@gmail.com') }

  it 'user is able to register to the site' do
    visit new_account_path(locale: :en)

    click_button 'Sign up for account'
    page.should have_content 'There were problems'

    fill_in 'user_login', with: 'John'
    fill_in 'user_email', with: 'john@gmail.com'
    fill_in 'user_password', with: 'very_secret'
    fill_in 'user_password_confirmation', with: 'very_secret'
    check 'user_accepts_terms'

    click_button 'Sign up for account'

    page.should have_content 'Your account has been created'
  end

  it 'user is able to log it to their profile' do
    login_as(OpenStruct.new(login: 'test', password: 'incorrect'))
    page.should have_content 'Username and/or password is incorrect'

    login_as(user)
    page.should have_content 'You was logged in successfuly'
  end

  it 'user is able to reset his password' do
    visit forgot_account_path(locale: :en)

    fill_in 'user_email', with: 'not_existing@email.com'
    click_button 'Submit'

    page.should have_content 'User not found'

    fill_in 'user_email', with: 'my@gmail.com'
    click_button 'Submit'

    page.should have_content 'Email was sent'
    last_email.should be
    last_email.to.should include 'my@gmail.com'

    visit restore_settings_user_path(id: user.reload.restoration_code, locale: :en)

    fill_in 'user_password', with: 'my_new_password'
    fill_in 'user_password_confirmation', with: 'my_new_password'
    click_button 'Update User'

    page.should have_content 'Password was changed'
    user.password = 'my_new_password'
    login_as(user)

    page.should have_content 'You was logged in successfuly'
  end

  it 'user is able to log out' do
    login_as(user)

    click_link 'Logout'

    page.should have_content 'You have been logged out'
  end

  it 'user can change information for his profile' do
    login_as(user)

    visit account_path(locale: :en)
    within('#profile') do
      fill_in 'user_name', with: 'Alf'
      fill_in 'user_about', with: 'The think from the space'
      fill_in 'user_email', with: 'alf@serial.com'
      click_button 'Save'
    end

    page.should have_content 'User data update was successfull.'

    user.reload.name.should eq 'Alf'
    user.reload.about.should match 'space'
    user.reload.email.should eq 'alf@serial.com'
  end

  it 'user can change his password' do
    login_as(user)
    change_password_to('very_secret')
    page.should have_content 'User data update was successfull.'
  end

  private

  def change_password_to(new_password)
    visit account_path(locale: :en)

    within('#password') do
      fill_in 'user_password', with: new_password
      fill_in 'user_password_confirmation', with: new_password
      click_button 'Save'
    end
  end
end