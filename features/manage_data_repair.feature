Feature: Data repair

  Background:
    Given there are fields in need of company data repair
    And I am a new, authenticated user "test" with password "password"

  @javascript
  Scenario: Show company data  to be repaired
    When I submit the company data form with the show results option
    Then I should see matching fields
