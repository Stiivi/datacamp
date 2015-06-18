require 'spec_helper'

describe 'Comments' do
  let!(:dataset) { FactoryGirl.create(:dataset_description, identifier: 'doctor', with_dataset: true) }
  let!(:field) { FactoryGirl.create(:field_description, identifier: 'name', dataset_description: dataset) }
  let!(:record) { dataset.dataset_record_class.create!(name: 'John') }
  let!(:user) { FactoryGirl.create(:user, is_super_user: false) }
  let!(:comment)  { FactoryGirl.create(:comment, record_id: record._record_id, text: 'Good record!', user: user, dataset_description: dataset) }

  context 'anonymous user' do
    it 'is able to see comments in dataset row' do

      visit dataset_record_path(dataset_id: dataset, id: record, locale: :en)

      page.should have_content 'Good record!'
    end
  end

  context 'registred user' do
    let(:adam_user) { FactoryGirl.create(:user, login: 'adam', password: 'very_secret', is_super_user: false) }

    before(:each) do
      login_as(adam_user)
    end

    it 'is able to write a comment' do
      visit dataset_record_path(dataset_id: dataset, id: record, locale: :en)

      fill_in 'comment_text', with: 'Nice one!'
      click_button 'Post'

      page.should have_content 'Nice one!'
    end

    it 'is able to reply to comment' do
      visit dataset_record_path(dataset_id: dataset, id: record, locale: :en)

      click_link 'Reply'

      fill_in 'comment_text', with: 'Thanks'
      click_button 'Post'

      page.should have_content 'Good record!'
      page.should have_content 'Thanks'
    end

    it 'is able to rate comment as useful' do
      visit dataset_record_path(dataset_id: dataset, id: record, locale: :en)

      page.should have_content 'Neutral'

      click_link 'Useful'

      page.should have_content '1 out of 1 find this comment useful'
    end

    it 'is able to rate comment as poor' do
      visit dataset_record_path(dataset_id: dataset, id: record, locale: :en)

      page.should have_content 'Neutral'

      click_link 'Poor'

      page.should have_content '0 out of 1 find this comment useful'
    end

    it 'is able to report comment' do
      visit dataset_record_path(dataset_id: dataset, id: record, locale: :en)
      click_link 'Report'

      fill_in 'comment_report_reason', with: 'some spam'
      click_button 'Report'

      comment.comment_reports.should have(1).record
    end
  end

  context 'admin user' do
    before(:each) do
      login_as(admin_user)
    end

    it 'is able to suspend comment' do
      visit dataset_record_path(dataset_id: dataset, id: record, locale: :en)
      click_link 'Suspend'

      page.should_not have_content comment.text
    end

    it 'is able to see all comments' do
      FactoryGirl.create(:comment, record_id: record._record_id, text: 'go home', is_suspended: true, user: FactoryGirl.create(:user, is_super_user: false), dataset_description: dataset)

      visit settings_comments_path(locale: :en)

      page.should have_content 'Good record'
      page.should have_content 'go home'
    end

    it 'is able to update comment' do
      visit edit_settings_comment_path(id: comment, locale: :en)

      fill_in 'comment_text', with: 'edited text'
      click_button 'Update Comment'

      page.should have_content 'edited text'
    end
  end
end