Given /^a donations parser exists$/ do
  FactoryGirl.create(:donations_parser)
end

When /^I run the donations parser$/ do
  visit parsers_path
  find("//*[@rel='show']").click

  fill_in 'year', with: '2012'
  find("//*[contains(@rel, 'run')]").click
end

Then /^I should be able to download the parsed csv$/ do
  page.should have_xpath("//a[@rel='download']")
end
