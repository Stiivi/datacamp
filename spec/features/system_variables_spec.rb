require 'spec_helper'

describe 'SystemVariables' do
  before(:each) do
    generate_system_variables_sample
    login_as(admin_user)
  end

  it 'user is able to change site settings' do
    visit settings_system_variables_path(locale: :en)

    fill_in 'site_name', with: 'AFP Datanest'
    click_button 'Save'

    SystemVariable.reload_variables

    visit root_path(locale: :en)
    page.should have_title 'AFP Datanest'
  end
end