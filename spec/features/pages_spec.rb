require 'spec_helper'

describe 'Pages' do
  it 'user can see a home page with news' do
    home_page.update_attributes(body: 'hello world!')
    Factory(:news, title: 'new dataset available', text: 'finance stuffs')

    visit root_path(locale: :en)

    page.should have_content 'hello world!'
    page.should have_content 'new dataset available'
    page.should have_content 'finance stuffs'
  end

  it 'user can see other requested page' do
    about_us = Factory(:page, title: 'About us', body: 'AFP is a good organization')

    visit page_path(id: about_us, locale: :en)

    page.should have_content 'AFP is a good organization'
  end

  context 'admin section' do
    let!(:about_us_page) { Factory(:page, en_title: 'About us', page_name: 'about_us') }

    before(:each) do
      login_as(admin_user)
    end

    it 'user is able to see pages listing' do
      visit settings_pages_path(locale: :en)

      page.should have_content 'about_us'
    end

    it 'user is able to create new page' do
      visit new_settings_page_path(locale: :en)

      click_button 'Create Page'
      page.should have_content 'There were problems'

      fill_in 'page_en_title', with: 'Contacts'
      fill_in 'page_page_name', with: 'contact'
      click_button 'Create Page'

      page.should have_content 'Contacts'
    end

    it 'user is able to update existing page' do
      visit edit_settings_page_path(id: about_us_page, locale: :en)

      fill_in 'page_en_title', with: 'About our team'
      fill_in 'page_page_name', with: 'about_us'
      click_button 'Update Page'

      page.should have_content 'About our team'
    end
  end
end