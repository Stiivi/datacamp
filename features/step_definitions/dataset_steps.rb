Given /^a published dataset "([^"]*)"$/ do |dataset_description_identifier|
  dataset_description = Factory(:dataset_description, :identifier => dataset_description_identifier, :en_title => dataset_description_identifier)
  And %{an empty dataset "#{dataset_description_identifier}"}
end

Given /^an empty dataset "([^"]*)"$/ do |dataset_description_identifier|
  dataset_class = load_dataset_model(dataset_description_identifier)
  dataset_class.delete_all
end

Given /^a published record exists for dataset "([^"]*)"$/ do |dataset_description_identifier|
  dataset_description = DatasetDescription.find_by_identifier(dataset_description_identifier)
  Factory.create(:field_description, :identifier => 'test', :dataset_description => dataset_description)
  dataset_class = dataset_description.dataset.dataset_record_class
  dataset_class.create(:record_status => 'published', :test => 'some content')
end

Given /^an unpublished record exists for dataset "([^"]*)"$/ do |dataset_description_identifier|
  dataset_description = DatasetDescription.find_by_identifier(dataset_description_identifier)
  Factory.create(:field_description, :identifier => 'test', :dataset_description => dataset_description)
  dataset_class = dataset_description.dataset.dataset_record_class
  dataset_class.create(:record_status => 'new', :test => 'some content')
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