# for this feature to run you need to have a table 'testing' and 'organisations' in your 'data' database for the testing environment. Please run db/data/ds_testing.sql and db/data/ds_organisations.sql

Feature: Data repair

  Background:
    Given there are fields in need of company data repair
    And I am a new, authenticated user "test" with password "password"
    And I am on the new_data_repair page
  
  @selenium
  Scenario: Show company data  to be repaired
    When I submit the company data form with the show results option
    Then I should see matching fields
  #   
  # Scenario: Repair company data
  #   When I submit the company data form with the repair option
  #   Then I should see how many fields were affected and the resulting values