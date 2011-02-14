Feature: User management

  Scenario: An existing user wants to edit their password
    Given I am a new, authenticated user "test" with password "password"
    When I go and change my password to "secretpassword"
    Then I should see "User data update was successfull."