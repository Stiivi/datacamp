# -*- encoding : utf-8 -*-
require 'test_helper'

class DatasetRecordTest < ActiveSupport::TestCase
  
  def setup
    prepare_record
  end
  
  test "should create Change upon changing value & saving" do
    test_school = @record_class.first
    test_school.name = "Some other name"
    
    assert_difference 'Change.count', 1 do
      test_school.save
    end
    
    assert_equal "Some other name", Change.last.value
    assert_equal "name", Change.last.field
  end
  
  test "should not create Change upon saving but not having anything changed" do
    test_school = @record_class.first
    
    assert_difference('Change.count', 0) do
      test_school.save
    end
  end
  
  
  private
  
  def prepare_record
    @description = DatasetDescription.first
    dataset = @description.dataset
    @record_class = dataset.dataset_record_class # returns isntance of DatasetRecord
  end
end
