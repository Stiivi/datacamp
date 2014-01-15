Given /^two published datasets with data exist$/ do
  Dataset::DcRelation.delete_all

  @lawyers = Factory(:dataset_description, :identifier => 'lawyers', :en_title => 'lawyers')
  @lawyer_associates = Factory(:dataset_description, :identifier => 'lawyer_associates', :en_title => 'lawyer_associates')

  Factory.create(:field_description, identifier: 'original_name', dataset_description: @lawyers, is_visible_in_relation: true)
  @lawyers.dataset.dataset_record_class.delete_all
  @lawyer_record = @lawyers.dataset.dataset_record_class.create!(original_name: 'Franz Kafka', record_status: 'published')

  Factory.create(:field_description, identifier: 'original_name', dataset_description: @lawyer_associates, is_visible_in_relation: true)
  @lawyer_associates.dataset.dataset_record_class.delete_all
  @lawyer_associate_record = @lawyer_associates.dataset.dataset_record_class.create!(original_name: 'Lionel Hutz', record_status: 'published', sak_id: 1)
end

When /^I setup a relation between the datasets$/ do
  visit relations_dataset_description_path(@lawyers, locale: :en)
  click_button('+')
  select(@lawyer_associates.identifier, :from => 'Relationship table')
  click_button('Save relations')
end

When /^I setup relations for both sides of the datasets$/ do
  step %{I setup a relation between the datasets}
  visit relations_dataset_description_path(@lawyer_associates, locale: :en)
  click_button('+')
  select(@lawyers.identifier, :from => 'Relationship table')
  click_button('Save relations')
end

When /^setup a relationship between the data$/ do
  @lawyer_record.ds_lawyer_associates << @lawyer_associate_record
end

Then /^I should see related data in on the detail page of a record$/ do
  visit dataset_record_path(@lawyers, @lawyers.dataset.dataset_record_class.first, locale: :en)
  page.should have_content(@lawyer_associates.dataset.dataset_record_class.first.original_name)
end

Then /^I should see related data in on the detail page of a record belonging to the second dataset$/ do
  step %{I should see related data in on the detail page of a record}
  visit dataset_record_path(@lawyer_associates, @lawyer_associates.dataset.dataset_record_class.first, locale: :en)
  page.should have_content(@lawyers.dataset.dataset_record_class.first.original_name)
end




Given /^a published dataset "([^"]*)"$/ do |dataset_description_identifier|
  dataset_description = Factory(:dataset_description, :identifier => dataset_description_identifier, :en_title => dataset_description_identifier, api_access_level: 1)
  step %{an empty dataset "#{dataset_description_identifier}"}
end

Given /^an empty dataset "([^"]*)"$/ do |dataset_description_identifier|
  dataset_class = load_dataset_model(dataset_description_identifier)
  dataset_class.delete_all
end

Given /^a published record exists for dataset "([^"]*)"$/ do |dataset_description_identifier|
  step %{a published record with "some content" exists for dataset "#{dataset_description_identifier}"}
end

Given /^a published record with "([^"]*)" exists for dataset "([^"]*)"$/ do |content, dataset_description_identifier|
  dataset_description = DatasetDescription.find_by_identifier(dataset_description_identifier)
  Factory.create(:field_description, identifier: 'test', dataset_description: dataset_description)
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
  step %{there is a "foreign_key" column in "#{dataset_class.table_name}"}
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
  step %{I go to the dataset descriptions page}
  step %{I follow "#{dataset_description_identifier}"}
  step %{I follow "Relations"}
  step %{I press "+"}
  step %{I select "#{relationship_type}" from "Relationship type"}
  step %{I select "#{dataset_description_identifier_for_relation}" from "Relationship table"}
  check('Create relationship field/table')
  step %{I press "Save relations"}
end

When /^I set up a "([^"]*)" relationship on "([^"]*)" to "([^"]*)" that needs the foreign key created$/ do |relationship_type, dataset_description_identifier, dataset_description_identifier_for_relation|
  step %{I go to the dataset descriptions page}
  step %{I follow "#{dataset_description_identifier}"}
  step %{I follow "Relations"}
  step %{I press "+"}
  step %{I select "#{relationship_type}" from "Relationship type"}
  step %{I select "#{dataset_description_identifier_for_relation}" from "Relationship table"}
  check('Create relationship field/table')
  step %{I press "Save relations"}
end

When /^I set up a "([^"]*)" relationship on "([^"]*)" to "([^"]*)"$/ do |relationship_type, dataset_description_identifier, dataset_description_identifier_for_relation|
  step %{I go to the dataset descriptions page}
  step %{I follow "#{dataset_description_identifier}"}
  step %{I follow "Relations"}
  step %{I press "+"}
  step %{I select "#{relationship_type}" from "Relationship type"}
  step %{I select "#{dataset_description_identifier_for_relation}" from "Relationship table"}
  step %{I press "Save relations"}
end

When /^I set up a "([^"]*)" relationship on "([^"]*)" to "([^"]*)" through "([^"]*)"$/ do |relationship_type, dataset_description_identifier, dataset_description_identifier_for_relation, through_table|
  step %{I go to the dataset descriptions page}
  step %{I follow "#{dataset_description_identifier}"}
  step %{I follow "Relations"}
  step %{I press "+"}
  step %{I select "#{relationship_type}" from "Relationship type"}
  step %{I select "#{dataset_description_identifier_for_relation}" from "Relationship table"}
  step %{I select "#{through_table}" from "Relation Table"}
  step %{I press "Save relations"}
end

When /^I display the first record for dataset "([^"]*)"$/ do |dataset|
  step %{I display records for dataset "#{dataset}"}
  step %{I follow "View"}
end

When /^I am logged in and showing records for dataset "([^"]*)"$/ do |dataset|
  step %{a published record exists for dataset "#{dataset}"}
  step %{I am a new, authenticated user "test" with password "password"}
  step %{I display records for dataset "#{dataset}"}
end

When /^I display records for dataset "([^"]*)"$/ do |dataset_description_identifier|
  dataset_description = DatasetDescription.find_by_identifier(dataset_description_identifier)
  visit dataset_path(dataset_description, locale: :en)
end

When /^I display page (\d+) of sorted records for dataset "([^"]*)"$/ do |page, dataset_description_identifier|
  dataset_description = DatasetDescription.find_by_identifier(dataset_description_identifier)
  visit dataset_path(dataset_description, page: page, sort: 'test', locale: :en)
end

When /^I batch edit selected records for a dataset to suspended$/ do
  step %{I am logged in and showing records for dataset "lawyers"}
  step %{I check "record[]"}
  step %{I select "Suspended" from "status"}
end

When /^I batch edit all records for a dataset to suspended$/ do
  step %{I am logged in and showing records for dataset "lawyers"}
  step %{I check "record[]"}
  step %{I select "All filtered records" from "selection"}
  step %{I select "Suspended" from "status"}
end

When /^I batch edit search results for a dataset to suspended$/ do
  step %{I am logged in and showing records for dataset "lawyers"}
  dataset_class = DatasetDescription.find_by_identifier("lawyers").dataset.dataset_record_class
  dataset_class.stubs(:search).returns(dataset_class.paginate(page: 1))
  find("//a[@class='button_disclosure']").click
  step %{I fill in "search[predicates][][value]" with "value"}
  find("//*[@id='search_advanced']//*[@class='search_button']").click
  step %{I check "record[]"}
  step %{I select "All filtered records" from "selection"}
  step %{I select "Suspended" from "status"}
end
