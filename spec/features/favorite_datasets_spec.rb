require 'spec_helper'

describe 'FavoriteDatasets' do
  context 'logged in user' do
    let!(:students) { Factory(:dataset_description, en_title: 'students', with_dataset: true) }
    let!(:field_description) { Factory(:field_description, identifier: 'name', dataset_description: students) }
    let!(:record) { students.dataset_record_class.create!(name: 'Filip Velky') }

    before(:each) do
      login_as(admin_user)
    end

    it 'is able to mark dataset record as favorite and see his favorite records in his profile', js: true do
      visit dataset_record_path(dataset_id: students, id: record, locale: :en)

      click_link 'Add to favorites'
      sleep(0.5)

      fill_in 'note', with: 'my friend'
      click_button 'Submit'
      sleep(0.5)

      click_link 'My Account'
      click_link 'Favorites'

      page.should have_content 'my friend', 'students', record._record_id.to_s
    end

    it 'user is able to remove record from favorites' do
      Factory(:favorite, user: admin_user, dataset_description: students, record: record, note: 'check this one later')

      visit dataset_record_path(dataset_id: students, id: record, locale: :en)

      click_link 'Remove from favorites'
      sleep(0.5)

      click_link 'My Account'
      click_link 'Favorites'

      page.should_not have_content 'check this one later', 'students'
    end
  end
end