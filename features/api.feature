Feature: API

  Scenario: download changes
    Given I am a new, authenticated user "test" with password "password"
    When I download changes for the first dataset
    Then I should see an xml containing changes