Feature: parsers

  In order to be able to parse data
  As an administrator
  I should be able to run parsers

  @wip
  Scenario: Run donations parser
    Given I am a new, authenticated user "test" with password "password"
    And a donations parser exists
    When I run the donations parser
    Then I should be able to download the parsed csv
