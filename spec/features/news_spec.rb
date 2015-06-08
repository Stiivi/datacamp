require 'spec_helper'

describe 'News' do
  context 'frontend' do
    let!(:dataset_news) { Factory(:news, title: 'new dataset available', text: 'finance stuffs') }

    it 'user can see news listing' do
      visit news_index_path(locale: :en)

      page_should_have_content_with 'new dataset available', 'finance stuffs'
    end

    it 'user can see news detail' do
      visit news_path(id: dataset_news, locale: :en)

      page_should_have_content_with 'new dataset available', 'finance stuffs'
    end
  end

  context 'admin section' do
    let!(:dataset_news) { Factory(:news, title: 'update available', text: 'read more') }

    before(:each) do
      login_as(admin_user)
    end

    it 'user is able to see news listing' do
      visit settings_news_index_path(locale: :en)

      page.should have_content 'update available'
    end

    it 'user is able to create new news' do
      visit new_settings_news_path(locale: :en)

      fill_in 'news_en_title', with: 'site improved'
      check 'news_published'
      click_button 'Create News'

      page.should have_content 'site improved'
    end

    it 'user is able to update existing news' do
      visit edit_settings_news_path(id: dataset_news, locale: :en)

      fill_in 'news_en_title', with: 'update will be there later'
      click_button 'Update News'

      page.should have_content 'update will be there later'
    end
  end
end