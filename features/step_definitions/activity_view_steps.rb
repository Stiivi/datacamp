Given /^some recent activity exists$/ do
  Factory(:change, user: User.first)
end

When /^I display the recent activities$/ do
  visit activities_path
end

Then /^I should see all of the recent activity that is in the database$/ do
  page.should have_content('cool_field')
  page.should have_content('new_field_value')
  page.should have_content('something')
  page.should have_content(User.first.name)
end

When /^I display the first activity$/ do
  And %{I display the recent activities}
  click_link('View')
end

Then /^I should see more information about the first activity$/ do
  activity = Change.first
  page.should have_content(activity.dataset_description_identifier)
  page.should have_content(activity.changed_field)
  page.should have_content(activity.value)
  page.should have_content(activity.user_name)
end