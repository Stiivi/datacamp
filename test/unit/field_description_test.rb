require 'test_helper'

class FieldDescriptionTest < ActiveRecord::TestCase
  test "should create a column in database when field description is created" do
    # We assume to have our schools dataset created by fixtures.rb file
    # (it's recreated everytime the tests are run)
    
    # So frist thing to do will be retrieving description, dataset, record ...
    # If it dies here we have problem with fixtures
    @description = DatasetDescription.find_by_identifier!("ds_schools")
    @dataset     = @description.dataset
    @record      = @dataset.dataset_record_class
    
    # Create the column
    column = {:identifier => "kind", :title => "Kind"}
    field_description = @description.field_descriptions.build(column)
    field_description.save
    @description.save
    
    # And it's time to look if such a column was created
    connection = DatasetRecord.connection # Same as @record.connection
    columns    = connection.columns(@record.table_name)
    
    has_column = columns.find { |c| c.name == column[:identifier] }
    
    assert has_column, "Can't find newly created column #{column[:identifier]} in #{@record.table_name} table."
        
  end
end