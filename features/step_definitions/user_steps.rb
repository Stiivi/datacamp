Given /^I have one\s+user "([^\"]*)" with password "([^\"]*)" and username "([^\"]*)"$/ do |email, password, username|
  User.create(:login => username, :email => email, :name => username, :password => password, :is_super_user => true, :password_confirmation => password, :accepts_terms => '1')
end

Given /^I am not authenticated$/ do
  step %{I go to the logout page}
  step %{I follow "English"}
end

Given /^I am a new, authenticated user "([^"]*)" with password "([^"]*)"$/ do |username, password|
  step %{I have one user "#{username}@email.com" with password "#{password}" and username "#{username}"}
  step %{I am not authenticated}
  step %{I am loged in as user "#{username}" with password "#{password}"}
end

Given /^I am loged in as user "([^"]*)" with password "([^"]*)"$/ do |username, password|
  step %{I go to the login page}
  step %{I fill in "Username" with "#{username}"}
  step %{I fill in "Password" with "#{password}"}
  step %{I press "Submit"}
end

When /^I go and change my password to "([^"]*)"$/ do |password|
  step %{I go to the account page}
  step %{I fill in "Password" with "#{password}"}
  step %{I fill in "Password confirmation" with "#{password}"}
  step %{I press "Save"}
end
