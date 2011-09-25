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
  Factory.create(:field_description, identifier: 'relation_id', dataset_description: dataset_description, sk_title: 'relation_id', en_title: 'relation_id')
  dataset_class = dataset_description.dataset.dataset_record_class
  dataset_class.create(record_status: 'published', test: content)
end

Given /^an unpublished record exists for dataset "([^"]*)"$/ do |dataset_description_identifier|
  dataset_description = DatasetDescription.find_by_identifier(dataset_description_identifier)
  Factory.create(:field_description, :identifier => 'test', :dataset_description => dataset_description)
  dataset_class = dataset_description.dataset.dataset_record_class
  dataset_class.create(:record_status => 'new', :test => 'some content')
end

When /^I set up a has_many relationship on "([^"]*)" to "([^"]*)" with foreign_key "([^"]*)"$/ do |dataset_description_identifier, dataset_description_identifier_for_relation, foreign_key|
  And %{I go to the dataset descriptions page}
  And %{I follow "testing"}
  And %{I follow "Relations"}
  And %{I select "has_many" from "Relationship type"}
  And %{I select "testing2" from "Relationship table"}
  And %{I press "Refresh foreign keys"}
  And %{I select "relation_id" from "Foreign key"}
  And %{I press "Save relations"}
  
  And %{I follow "Visibility settings"}
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
  And %{I am logged in and showing records for dataset "testing"}
  And %{I check "record[]"}
  And %{I select "Suspended" from "status"}
end

When /^I batch edit all records for a dataset to suspended$/ do
  And %{I am logged in and showing records for dataset "testing"}
  And %{I check "record[]"}
  And %{I select "All records" from "selection"}
  And %{I select "Suspended" from "status"}
end

When /^I batch edit search results for a dataset to suspended$/ do
  And %{I am logged in and showing records for dataset "testing"}
  dataset_class = DatasetDescription.find_by_identifier("testing").dataset.dataset_record_class
  dataset_class.stubs(:search).returns(dataset_class.paginate(page: 1))
  And %{I follow "Search"}
  And %{I fill in "search[predicates][][value]" with "value"}
  And %{I press "Submit"}
  And %{I check "record[]"}
  And %{I select "All records" from "selection"}
  And %{I select "Suspended" from "status"}
end