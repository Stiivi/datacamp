require 'spec_helper'

describe 'DatasetDescriptions' do
  before(:each) do
    login_as(admin_user)
  end

  it 'user is able to initialize dataset description' do
    create_table_for_initialization
    DcForInitialization = Class.new(Dataset::DatasetRecord)
    DcForInitialization.create!(name: 'hello', info: 'description', value: 5, price: 9.5)

    visit dataset_initializations_path(locale: :en)

    within '#dc_for_initializations' do
      click_link 'Initialize'
    end

    page.should_not have_content 'dc_for_initializations'

    dataset = DatasetDescription.find_by_identifier!('dc_for_initializations')
    dataset.dataset_model.should have(1).record
  end

  def create_table_for_initialization
    if Dataset.connection.tables.include?('dc_for_initializations')
      Dataset.connection.drop_table :dc_for_initializations
    end
    Dataset.connection.create_table :dc_for_initializations, primary_key: :_record_id do |t|
      t.string :name
      t.text :info
      t.integer :value
      t.decimal :price, precision: 10, scale: 2

      t.timestamps
    end
  end
end