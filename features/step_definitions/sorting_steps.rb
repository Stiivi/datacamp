When /^I reorder field descriptions for the first dataset$/ do
  Factory.create(:field_description,
                 identifier: 'another_name',
                 dataset_description: @lawyers,
                 is_visible_in_relation: true)
  dataset_1 = DatasetDescription.first
  visit dataset_description_path(id: dataset_1.id)

  find("//a[contains(@class, 'sort_link')]").click

  drop_place = find("//footer")
  find("//div[@id='field_descriptions']").find(".//li[@class='field_description'][1]//img").drag_to(drop_place)
  find("//a[contains(@class, 'finish_sort_link')]").click
end

Then /^I should see the filed descriptions in the new order$/ do
  within(:xpath, "//div[@id='field_descriptions']//li[@class='field_description']") do
    should have_content('another_name')
  end
end
