Given /^I have one\s+user "([^\"]*)" with password "([^\"]*)" and username "([^\"]*)"$/ do |email, password, username|
  User.create(:login => username, :email => email, :name => username, :password => password, :is_super_user => true, :password_confirmation => password, :accepts_terms => '1')
end

Given /^I am not authenticated$/ do
  And %{I go to the logout page}
end

Given /^I am a new, authenticated user "([^"]*)" with password "([^"]*)"$/ do |username, password|
  Given %{I have one user "#{username}@email.com" with password "#{password}" and username "#{username}"}
  And %{I am not authenticated}
  And %{I am loged in as user "#{username}" with password "#{password}"}
end

Given /^I am loged in as user "([^"]*)" with password "([^"]*)"$/ do |username, password|
  And %{I go to the login page}
  And %{I fill in "Username" with "#{username}"}
  And %{I fill in "Password" with "#{password}"}
  And %{I press "Submit"}
end

When /^I go and change my password to "([^"]*)"$/ do |password|
  And %{I go to the account page}
end
