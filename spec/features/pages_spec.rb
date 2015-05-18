require 'spec_helper'

describe 'Pages' do
  it 'user can see a home page with news' do
    home_page.update_attribute(:body, 'hello world!')
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
end