Given /^a published dataset "([^"]*)"$/ do |dataset_description_identifier|
  dataset_description = Factory(:dataset_description, :identifier => dataset_description_identifier, :en_title => dataset_description_identifier)
  And %{an empty dataset "#{dataset_description_identifier}"}
end

Given /^an empty dataset "([^"]*)"$/ do |dataset_description_identifier|
  dataset_class = load_dataset_model(dataset_description_identifier)
  dataset_class.delete_all
end

Given /^a published record exists for dataset "([^"]*)"$/ do |dataset_description_identifier|
  And %{a published record with "some content" exists for dataset "#{dataset_description_identifier}"}
end

Given /^a published record with "([^"]*)" exists for dataset "([^"]*)"$/ do |content, dataset_description_identifier|
  dataset_description = DatasetDescription.find_by_identifier(dataset_description_identifier)
  Factory.create(:field_description, identifier: 'test', dataset_description: dataset_description)
  Factory.create(:field_description, identifier: 'id', dataset_description: dataset_description, sk_title: 'id', en_title: 'id')
  dataset_class = dataset_description.dataset.dataset_record_class
  @record = dataset_class.create(record_status: 'published', test: content)
end


When /^a published record for dataset "([^"]*)" with a related record for dataset "([^"]*)" through "([^"]*)"$/ do |dataset, related_adataset, through_table|
  load_dataset_model(dataset).delete_all
  load_dataset_model(related_adataset).delete_all
  "Kernel::#{through_table.classify}".constantize.delete_all
  
  dataset_description = DatasetDescription.find_by_identifier(dataset)
  relation_dataset_description = DatasetDescription.find_by_identifier(related_adataset)
  
  Factory.create(:field_description, identifier: 'name', dataset_description: dataset_description)
  Factory.create(:field_description, identifier: 'first_name', dataset_description: relation_dataset_description, is_visible_in_relation: true)
  
  dd = dataset_description.dataset.dataset_record_class.create(record_status: 'published', name: 'some content')
  rdd = relation_dataset_description.dataset.dataset_record_class.create(record_status: 'published', first_name: 'some content2')
  "Kernel::#{through_table.classify}".constantize.create(ds_advokat_id: dd._record_id, ds_trainee_id: rdd._record_id)
end

Given /^a published record with "([^"]*)" exists for relation dataset "([^"]*)"$/ do |content, dataset_description_identifier|
  foreign_key = "#{@record.class.table_name.singularize}_id"
  dataset_description = DatasetDescription.find_by_identifier(dataset_description_identifier)
  Factory.create(:field_description, identifier: 'test', dataset_description: dataset_description, is_visible_in_relation: true)
  Factory.create(:field_description, identifier: foreign_key, dataset_description: dataset_description, sk_title: foreign_key, en_title: foreign_key)
  dataset_class = dataset_description.dataset.dataset_record_class
  And %{there is a "foreign_key" column in "#{dataset_class.table_name}"}
  dataset_class.create(:record_status => 'published', :test => content, foreign_key.to_sym => @record._record_id)
end

Given /^an unpublished record exists for dataset "([^"]*)"$/ do |dataset_description_identifier|
  dataset_description = DatasetDescription.find_by_identifier(dataset_description_identifier)
  Factory.create(:field_description, :identifier => 'test', :dataset_description => dataset_description)
  dataset_class = dataset_description.dataset.dataset_record_class
  dataset_class.create(:record_status => 'new', :test => 'some content')
end

Given /^there is not a "([^"]*)" column in "([^"]*)"$/ do |column, table|
  FieldDescription.where(identifier: column).delete_all
  Dataset::DatasetRecord.connection.remove_column(table, column) if Dataset::DatasetRecord.connection.columns(table).map(&:name).include?(column)
end

Given /^there is a "([^"]*)" column in "([^"]*)"$/ do |column, table|
  Dataset::DatasetRecord.connection.add_column(table, column, :integer) unless Dataset::DatasetRecord.connection.columns(table).map(&:name).include?(column)
end

Given /^there is a relation table "([^"]*)" with fields "([^"]*)" and "([^"]*)"$/ do |relation_table_name, first_field, second_field|
  Dataset::DatasetRecord.connection.create_table(relation_table_name, primary_key: '_record_id') do |t|
    t.integer first_field
    t.integer second_field
  end unless Dataset::DatasetRecord.connection.table_exists?(relation_table_name)
end

Given /^there are no tables with prefix "([^"]*)"$/ do |prefix|
  Dataset::Base.find_tables(prefix: prefix).each do |table_name| 
    Dataset::DatasetRecord.connection.drop_table(table_name) if Dataset::DatasetRecord.connection.table_exists?(table_name)
  end
end

When /^I set up a "([^"]*)" relationship on "([^"]*)" to "([^"]*)" through "([^"]*)" that needs the relationship table created$/ do |relationship_type, dataset_description_identifier, dataset_description_identifier_for_relation, through_table|
  And %{I go to the dataset descriptions page}
  And %{I follow "#{dataset_description_identifier}"}
  And %{I follow "Relations"}
  And %{I press "+"}
  And %{I select "#{relationship_type}" from "Relationship type"}
  And %{I select "#{dataset_description_identifier_for_relation}" from "Relationship table"}
  check('Create relationship field/table')
  And %{I press "Save relations"}
end

When /^I set up a "([^"]*)" relationship on "([^"]*)" to "([^"]*)" that needs the foreign key created$/ do |relationship_type, dataset_description_identifier, dataset_description_identifier_for_relation|
  And %{I go to the dataset descriptions page}
  And %{I follow "#{dataset_description_identifier}"}
  And %{I follow "Relations"}
  And %{I press "+"}
  And %{I select "#{relationship_type}" from "Relationship type"}
  And %{I select "#{dataset_description_identifier_for_relation}" from "Relationship table"}
  check('Create relationship field/table')
  And %{I press "Save relations"}
end

When /^I set up a "([^"]*)" relationship on "([^"]*)" to "([^"]*)"$/ do |relationship_type, dataset_description_identifier, dataset_description_identifier_for_relation|
  And %{I go to the dataset descriptions page}
  And %{I follow "#{dataset_description_identifier}"}
  And %{I follow "Relations"}
  And %{I press "+"}
  And %{I select "#{relationship_type}" from "Relationship type"}
  And %{I select "#{dataset_description_identifier_for_relation}" from "Relationship table"}
  And %{I press "Save relations"}
end

When /^I set up a "([^"]*)" relationship on "([^"]*)" to "([^"]*)" through "([^"]*)"$/ do |relationship_type, dataset_description_identifier, dataset_description_identifier_for_relation, through_table|
  And %{I go to the dataset descriptions page}
  And %{I follow "#{dataset_description_identifier}"}
  And %{I follow "Relations"}
  And %{I press "+"}
  And %{I select "#{relationship_type}" from "Relationship type"}
  And %{I select "#{dataset_description_identifier_for_relation}" from "Relationship table"}
  And %{I select "#{through_table}" from "Relation Table"}
  And %{I press "Save relations"}
end

When /^I display the first record for dataset "([^"]*)"$/ do |dataset|
  And %{I display records for dataset "#{dataset}"}
  And %{I follow "View"}
end

When /^I am logged in and showing records for dataset "([^"]*)"$/ do |dataset|
  And %{a published record exists for dataset "#{dataset}"}
  And %{I am a new, authenticated user "test" with password "password"}
  When %{I display records for dataset "#{dataset}"}
end

When /^I display records for dataset "([^"]*)"$/ do |dataset_description_identifier|
  dataset_description = DatasetDescription.find_by_identifier(dataset_description_identifier)
  visit dataset_path(dataset_description)
end

When /^I display page (\d+) of sorted records for dataset "([^"]*)"$/ do |page, dataset_description_identifier|
  dataset_description = DatasetDescription.find_by_identifier(dataset_description_identifier)
  visit dataset_path(dataset_description, :page => page, :sort => 'test')
end

When /^I batch edit selected records for a dataset to suspended$/ do
  And %{I am logged in and showing records for dataset "testings"}
  And %{I check "record[]"}
  And %{I select "Suspended" from "status"}
end

When /^I batch edit all records for a dataset to suspended$/ do
  And %{I am logged in and showing records for dataset "testings"}
  And %{I check "record[]"}
  And %{I select "All records" from "selection"}
  And %{I select "Suspended" from "status"}
end

When /^I batch edit search results for a dataset to suspended$/ do
  And %{I am logged in and showing records for dataset "testings"}
  dataset_class = DatasetDescription.find_by_identifier("testings").dataset.dataset_record_class
  dataset_class.stubs(:search).returns(dataset_class.paginate(page: 1))
  And %{I follow "Search"}
  And %{I fill in "search[predicates][][value]" with "value"}
  And %{I press "Submit"}
  And %{I check "record[]"}
  And %{I select "All records" from "selection"}
  And %{I select "Suspended" from "status"}
end