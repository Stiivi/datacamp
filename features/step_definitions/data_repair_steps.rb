# -*- encoding : utf-8 -*-
Given /^there are fields in need of company data repair$/ do
  And %{a published dataset "testings"}
  And %{a published dataset "organisations"}
  dataset_description = DatasetDescription.find_by_identifier("organisations")
  Factory.create(:field_description, :title => 'ico', :identifier => 'ico', :dataset_description => dataset_description)
  Factory.create(:field_description, :title => 'name', :identifier => 'name', :dataset_description => dataset_description)
  Factory.create(:field_description, :title => 'address', :identifier => 'address', :dataset_description => dataset_description)
  And %{ico repair field descriptions for dataset dataset "testings" exist}
  And %{a record with ico, company_name and company_address fields exists for dataset "testings"}
  And %{a record with ico, company_name fields exists for dataset "testings"}
  And %{a record with ico, company_address fields exists for dataset "testings"}
  And %{a record with ico field exists for dataset "testings"}
end

Given /^ico repair field descriptions for dataset dataset "([^"]*)" exist$/ do |dataset_description_identifier|
  dataset_description = DatasetDescription.find_by_identifier(dataset_description_identifier)
  Factory.create(:field_description, :title => 'ico', :identifier => 'ico', :dataset_description => dataset_description)
  Factory.create(:field_description, :identifier => 'company_name', :dataset_description => dataset_description)
  Factory.create(:field_description, :identifier => 'company_address', :dataset_description => dataset_description)
end

Given /^a record with ico, company_name and company_address fields exists for dataset "([^"]*)"$/ do |dataset_description_identifier|
  load_dataset_model(dataset_description_identifier).create(:record_status => 'published', :ico => '123456', :company_name => 'some company full', :company_address => 'some company address full')
end

Given /^a record with ico, company_name fields exists for dataset "([^"]*)"$/ do |dataset_description_identifier|
  load_dataset_model(dataset_description_identifier).create(:record_status => 'published', :ico => '789123', :company_name => 'some company only name')
  load_dataset_model('organisations').create(:ico => '789123')
end

Given /^a record with ico, company_address fields exists for dataset "([^"]*)"$/ do |dataset_description_identifier|
  load_dataset_model(dataset_description_identifier).create(:record_status => 'published', :ico => '456789123', :company_address => 'some company address only address')
end

Given /^a record with ico field exists for dataset "([^"]*)"$/ do |dataset_description_identifier|
  dataset_description = DatasetDescription.find_by_identifier(dataset_description_identifier)
  dataset_class = dataset_description.dataset.dataset_record_class
  dataset_class.create(:record_status => 'published', :ico => '987654321')
end

When /^I submit the company data form with the show results option$/ do
  And %{I select "organisations" from "Regis table"}
  And %{I select "ico" from "Regis ico column"}
  And %{I select "name" from "Regis name column"}
  And %{I select "address" from "Regis address column"}
  
  And %{I select "test" from "Target table"}
  And %{I select "ico" from "Target ico column"}
  And %{I select "name" from "Target name column"}
  And %{I select "address" from "Target address column"}
  
  And %{I press "Show matching items"}
end

Then /^I should see matching fields$/ do
  And %{I should see "789123"}
  And %{I should see "some company only name"}
end
