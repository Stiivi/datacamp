# -*- encoding : utf-8 -*-
Given /^there are fields in need of company data repair$/ do
  step %{a published dataset "lawyers"}
  step %{a published dataset "organisations"}
  dataset_description = DatasetDescription.find_by_identifier("organisations")
  Factory.create(:field_description, :title => 'ico', :identifier => 'ico', :dataset_description => dataset_description)
  Factory.create(:field_description, :title => 'name', :identifier => 'name', :dataset_description => dataset_description)
  Factory.create(:field_description, :title => 'address', :identifier => 'address', :dataset_description => dataset_description)
  step %{ico repair field descriptions for dataset dataset "lawyers" exist}
  step %{a record with ico, company_name and company_address fields exists for dataset "lawyers"}
  step %{a record with ico, company_name fields exists for dataset "lawyers"}
  step %{a record with ico, company_address fields exists for dataset "lawyers"}
  step %{a record with ico field exists for dataset "lawyers"}
end

Given /^ico repair field descriptions for dataset dataset "([^"]*)" exist$/ do |dataset_description_identifier|
  dataset_description = DatasetDescription.find_by_identifier(dataset_description_identifier)
  Factory.create(:field_description, :title => 'ico', :identifier => 'ico', :dataset_description => dataset_description)
  Factory.create(:field_description, :identifier => 'company_name', :dataset_description => dataset_description)
  Factory.create(:field_description, :identifier => 'company_address', :dataset_description => dataset_description)
end

Given /^a record with ico, company_name and company_address fields exists for dataset "([^"]*)"$/ do |dataset_description_identifier|
  load_dataset_model(dataset_description_identifier).create(:record_status => 'published', :ico => '123456', :company_name => 'some company full', :company_address => 'some company address full', :sak_id => 1)
end

Given /^a record with ico, company_name fields exists for dataset "([^"]*)"$/ do |dataset_description_identifier|
  load_dataset_model(dataset_description_identifier).create(:record_status => 'published', :ico => '789123', :company_name => 'some company only name', :sak_id => 2)
  load_dataset_model('organisations').create(:ico => '789123')
end

Given /^a record with ico, company_address fields exists for dataset "([^"]*)"$/ do |dataset_description_identifier|
  load_dataset_model(dataset_description_identifier).create(:record_status => 'published', :ico => '456789123', :company_address => 'some company address only address', :sak_id => 3)
end

Given /^a record with ico field exists for dataset "([^"]*)"$/ do |dataset_description_identifier|
  dataset_description = DatasetDescription.find_by_identifier(dataset_description_identifier)
  dataset_class = dataset_description.dataset.dataset_record_class
  dataset_class.create(:record_status => 'published', :ico => '987654321')
end

When /^I submit the company data form with the show results option$/ do
  visit new_data_repair_path(locale: :en)
  step %{I select "organisations" from "Regis table"}
  sleep 1 #phantomjs does not wait for the following select boxes to be populated by ajax
  step %{I select "ico" from "Regis ico column"}
  step %{I select "name" from "Regis name column"}
  step %{I select "address" from "Regis address column"}

  step %{I select "lawyers" from "Target table"}
  sleep 1 #phantomjs does not wait for the following select boxes to be populated by ajax
  step %{I select "ico" from "Target ico column"}
  step %{I select "company_name" from "Target name column"}
  step %{I select "company_address" from "Target address column"}
  step %{I press "Show matching items"}
end

Then /^I should see matching fields$/ do
  step %{I should see "789123"}
  step %{I should see "some company only name"}
end
