require 'spec_helper'

describe 'FavoriteDatasets' do
  context 'logged in user' do
    let!(:students) { FactoryGirl.create(:dataset_description, en_title: 'students', with_dataset: true) }
    let!(:field_description) { FactoryGirl.create(:field_description, identifier: 'name', dataset_description: students) }
    let!(:record) { students.dataset_model.create!(name: 'Filip Velky') }

    before(:each) do
      login_as(admin_user)
    end

    it 'is able to mark dataset record as favorite and see his favorite records in his profile', js: true do
      visit dataset_record_path(dataset_id: students, id: record, locale: :en)

      click_link 'Add to favorites'

      fill_in 'note', with: 'my friend'
      click_button 'Submit'
      page.should have_link 'Remove from favorites'

      click_link 'My Account'
      click_link 'Favorites'

      within('#favorites') do
        page_should_have_content_with 'my friend', 'students', record.id.to_s
      end
    end

    it 'user is able to remove record from favorites', js: true do
      FactoryGirl.create(:favorite, user: admin_user, dataset_description: students, record: record, note: 'check this one later')

      visit dataset_record_path(dataset_id: students, id: record, locale: :en)

      click_link 'Remove from favorites'
      page.should have_link 'Add to favorites'

      click_link 'My Account'
      click_link 'Favorites'

      within('#favorites') do
        page_should_not_have_content_with 'check this one later', 'students'
      end
    end
  end
end