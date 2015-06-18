require 'spec_helper'

describe 'Blocks' do
  let!(:announcement_block) { FactoryGirl.create(:block, name: 'announcement') }

  before(:each) do
    login_as(admin_user)
  end

  it 'user is able to see blocks listing' do
    visit settings_blocks_path(locale: :en)

    page.should have_content 'announcement'
  end

  it 'user is able to create new block' do
    visit new_settings_block_path(locale: :en)

    click_button 'Create Block'
    page.should have_content 'There were problems'

    fill_in 'block_name', with: 'big message'
    click_button 'Create Block'

    page.should have_content 'big message'
  end

  it 'user is able to update existing block' do
    visit edit_settings_block_path(id: announcement_block, locale: :en)

    fill_in 'block_name', with: 'big msg 2'
    click_button 'Update Block'

    page.should have_content 'big msg 2'
  end

  it 'user is able to destroy existing block' do
    visit settings_blocks_path(locale: :en)

    within("#block_#{announcement_block.id}") do
      click_link 'Delete'
    end

    page.should_not have_content 'announcement'
  end
end