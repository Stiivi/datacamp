Feature: Activity overview
  
  In order to be able to see what is happening and what changes are being made to the datasets
  As an administrator
  I want to be able to display recent activity on all datasets
  
  Scenario: Display a table containing recent activity
    Given I am a new, authenticated user "test" with password "password"
    And some recent activity exists
    When I display the recent activities
    Then I should see all of the recent activity that is in the database