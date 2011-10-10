# -*- encoding : utf-8 -*-
module Dataset::Fixtures
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def dataset_fixtures
      # FIXME this should be loaded from a file ... But we want 
      # to get something working ASAP, so fixme for now ...
      
      # We want to delete all dataset descriptions
      DatasetDescription.delete_all
      FieldDescription.delete_all
      
      # We also want to delete everything from test_data table
      connection = Dataset::DatasetRecord.connection
      connection.tables.each do |table|
        connection.drop_table(table)
      end
      
      schools_desc = DatasetDescription.new(:identifier => "schools", :title => "Schools")
      schools_desc.save
      
      # We could also use some fields, hm?
      schools_desc.field_descriptions.create(:title => "Name", :identifier => "name")
      schools_desc.field_descriptions.create(:title => "City", :identifier => "city")
      
      schools_dataset = schools_desc.dataset
      schools_dataset.setup_table
      schools_peer = schools_dataset.dataset_record_class
      
      # OK, so now we have fields, let's load some data
      test_school = schools_peer.new(:name => "Test school", :city => "Test city")
      test_school.save
    end
  end
end
