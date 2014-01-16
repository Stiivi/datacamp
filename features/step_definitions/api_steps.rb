When /^I download changes for the first dataset$/ do
  step %{a published dataset "lawyers"}
  Dataset::DcUpdate.create(updatable_id: 42, updatable_type: 'Kernel::DsLawyer', updated_column: 'zip', original_value: '123456', new_value: '456789')

  visit datasets_path
  find("//a[contains(@class,'js_catalog_dataset_link')]").click
  find("//a[@rel='download-changes']").click
end

Then /^I should see an xml containing changes$/ do
  page.should have_content("Kernel::DsLawyer")
  page.should have_content("")
end
