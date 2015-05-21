require 'spec_helper'

describe 'DatasetDescriptions' do
  before(:each) do
    login_as(admin_user)
  end

  let!(:lists_category) { Factory(:dataset_category, title: 'lists') }
  let(:documents_category) { Factory(:dataset_category, title: 'documents') }

  it 'user can see dataset grouped by categories' do
    Factory(:dataset_description, en_title: 'lawyers', is_active: true, category: lists_category)
    Factory(:dataset_description, en_title: 'doctors', is_active: false, category: lists_category)
    Factory(:dataset_description, en_title: 'set with no category', is_active: false, category: nil)

    visit dataset_descriptions_path(locale: :en)

    page.should have_content 'lists'
    page.should have_content 'inactive'
    has_datasets_in_category(['lawyers', 'doctors'], lists_category)

    page.should have_content 'set with no category'
  end

  it 'user is able to create new dataset' do
    visit new_dataset_description_path(locale: :en)

    click_button 'Save'

    page.should have_content 'can\'t be blank'

    fill_in 'dataset_description_en_title', with: 'companies'
    fill_in 'dataset_description_sk_title', with: 'firmy'
    fill_in 'dataset_description_identifier', with: 'companies'
    select 'lists', from: 'dataset_description_category_id'

    click_button 'Save'

    page.should have_content 'Dataset created'

    visit dataset_descriptions_path(locale: :en)
    has_datasets_in_category(['companies'], lists_category)
  end

  it 'user is able to create new dataset with new category' do
    visit new_dataset_description_path(locale: :en)

    click_button 'Save'

    page.should have_content 'can\'t be blank'

    fill_in 'dataset_description_en_title', with: 'companies'
    fill_in 'dataset_description_sk_title', with: 'firmy'
    fill_in 'dataset_description_identifier', with: 'companies'
    fill_in 'dataset_description_category', with: 'public documents'

    click_button 'Save'

    page.should have_content 'Dataset created'

    visit dataset_descriptions_path(locale: :en)
    has_datasets_in_category(['companies'], DatasetCategory.find_by_title!('public documents'))
  end

  it 'user is able to edit dataset' do
    dataset_description = Factory(:dataset_description, en_title: 'doctors', is_active: true, category: lists_category)
    visit edit_dataset_description_path(id: dataset_description, locale: :en)

    fill_in 'dataset_description_en_title', with: ''

    click_button 'Save'
    page.should have_content 'can\'t be blank'

    fill_in 'dataset_description_en_title', with: 'court doctors'
    click_button 'Save'

    page.should have_content 'DatasetDescription was successfully updated'
  end

  it 'user is able to destroy dataset' do
    dataset_description = Factory(:dataset_description, en_title: 'doctors', is_active: true, category: lists_category)

    visit dataset_descriptions_path(locale: :en)

    within("#dataset_description_#{dataset_description.id}") do
      click_link 'Delete'
    end

    visit dataset_descriptions_path(locale: :en)
    does_not_have_datasets_in_category('doctors', lists_category)
  end

  it 'user is able to change dataset ordering and move dataset to different category by sorting', js: true do
    lawyers = Factory(:dataset_description, en_title: 'lawyers', is_active: true, category: documents_category)
    doctors = Factory(:dataset_description, en_title: 'doctors', is_active: false, category: lists_category)
    general = Factory(:dataset_description, en_title: 'general', is_active: false, category: nil)

    visit dataset_descriptions_path(locale: :en)

    has_datasets_in_category(['lawyers'], documents_category)

    click_link 'Sort'
    move_field_to_category(lawyers, lists_category)
    move_field_to_category(general, lists_category)
    click_link 'Finish sorting'
    sleep(0.5)

    visit dataset_descriptions_path(locale: :en)

    has_datasets_in_category(['lawyers', 'doctors', 'general'], lists_category)
  end

  it 'user is able to initialize dataset description' do
    create_table_for_initialization
    DcForInitialization = Class.new(Dataset::DatasetRecord)
    DcForInitialization.create!(name: 'hello', info: 'description', value: 5, price: 9.5)

    visit import_dataset_descriptions_path(locale: :en)

    within '#dc_for_initializations' do
      click_link 'Initialize'
    end

    page.should_not have_content 'dc_for_initializations'

    dataset = DatasetDescription.find_by_identifier!('dc_for_initializations')
    dataset.dataset_record_class.should have(1).record
  end

  private

  def has_datasets_in_category(dataset_names, category)
    within("li#dataset_category_#{category.id}") do
      page.should have_content *dataset_names
    end
  end

  def does_not_have_datasets_in_category(dataset_names, category)
    within("li#dataset_category_#{category.id}") do
      page.should_not have_content *dataset_names
    end
  end

  def move_field_to_category(dataset, category)
    drop_place = find("li#dataset_category_#{category.id} ul li:first-child")
    find("li#dataset_description_#{dataset.id} img.drag_arrow").drag_to(drop_place)
    timeout(10.seconds) do
      while all("li#dataset_category_#{category.id} li#dataset_description_#{dataset.id}").count == 0
        sleep(0.1)
      end
    end
  end

  def create_table_for_initialization
    Dataset::DatasetRecord.connection.create_table :dc_for_initializations, primary_key: :_record_id do |t|
      t.string :name
      t.text :info
      t.integer :value
      t.decimal :price, precision: 10, scale: 2

      t.timestamps
    end
  end
end