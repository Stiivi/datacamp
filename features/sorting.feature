Feature: Sorting items

  In order to controll the display order of things
  A data manager
  Should be able to drag items around in lists

  @javascript
  Scenario: Reorder field description information
    Given two published datasets with data exist
    And I am a new, authenticated user "test" with password "password"
    When I reorder field descriptions for the first dataset
    Then I should see the filed descriptions in the new order
