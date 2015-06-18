Feature: Datasets with relations

  In order to be able to publish data with database realtion
  As an administrator
  I want to be able to publish a dataset that has a relation defined and displays fields from the related table

  Background:
    Given I am a new, authenticated user "test" with password "password"

  Scenario: Publish a table with a relationship
    Given two published datasets with data exist
    When I setup a relation between the datasets
    And setup a relationship between the data
    Then I should see related data in on the detail page of a record

  Scenario: A relation create for one side has to work both ways
    Given two published datasets with data exist
    When I setup relations for both sides of the datasets
    And setup a relationship between the data
    Then I should see related data in on the detail page of a record
    Then I should see related data in on the detail page of a record belonging to the second dataset
