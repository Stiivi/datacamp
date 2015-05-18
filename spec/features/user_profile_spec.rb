require 'spec_helper'

describe 'UserProfile' do
  let(:user) { Factory(:user, login: 'test', password: 'secret') }

  it 'user is able to log it to their profile' do
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