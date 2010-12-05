require 'test_helper'

class DatasetBaseTest < ActiveSupport::TestCase
  
  def setup
    load_dataset
  end
  
  
  #################################################################################
  # Basic tests
  #################################################################################
  
  test "should find dataset and record based on description" do
    assert @record_class, "Dataset::Base returnde nil instead of record class"
    assert @record_class.superclass == DatasetRecord, "Dataset record class is not a DatasetRecord"
    assert_equal @dataset.table_name, @dataset.class.prefix + @desc.identifier, "name of the class should be equal to identifier in description"
    assert @dataset.table_exists?, "table #{@dataset.table_name} doesn't exist!"
  end
  
  test "should find dataset and class based on symbol" do
    identifier = @desc.identifier
    
    dataset = Dataset::Base.new(identifier.to_sym)
    assert dataset, "Dataset::Base#new returned nil when passing #{identifier}"
    assert dataset.table_exists?, "Table #{identifier} doesn't exist."
  end
  
  
  #################################################################################
  # Transformations tests
  #################################################################################
  
  test "should create a new table based on dataset description" do
    description = DatasetDescription.new(:identifier => "people", :title => "People")
    
    assert_difference 'DatasetDescription.count' do
      description.save
    end
    
    description.field_descriptions.create(:identifier => "name", :title => "Name")
    description.field_descriptions.create(:identifier => "surname", :title => "Surname")
    description.save
    
    dataset = description.dataset
    dataset.setup_table
    assert dataset.table_exists?, "table #{dataset.table_name} doesn't exist"
  end
  
  test "should transform a table into dataset" do
    # Create dummy table without pk
    @connection.create_table "dummy_table_without_pk", :id => false do |t|
      t.string "dummy_string"
      t.text "dummy_text"
    end
    
    dataset = Dataset::Base.new("dummy_table_without_pk")
    dataset.transform!
    assert !dataset.has_column?("id"), "it has an id column"
    assert dataset.has_column?("_record_id"), "it doesn't have _record_id column"
    # TODO Check if _record_id is PK?
    
    # Create dummy table with pk
    @connection.create_table "dummy_table_with_pk" do |t|
      t.string "dummy_string"
      t.text "dummy_text"
    end
    
    dataset = Dataset::Base.new("dummy_table_with_pk")
    dataset.transform!
    assert dataset.has_column?("id"), "it doesn't have an id column"
    assert dataset.has_column?("_record_id"), "it doesn't have _record_id column"
  end
  
  private
  
  def load_dataset
    @desc = DatasetDescription.find(:first)
    puts @desc.inspect
    @dataset = @desc.dataset
    @record_class = @dataset.dataset_record_class
    @connection = DatasetRecord.connection
  end
end