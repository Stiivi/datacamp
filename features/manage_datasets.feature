Feature: Dataset management and display

  Background:
    Given two published datasets with data exist

  @ds_testing_table
  Scenario: A dataset record that is published should be shown to all users
    When I display records for dataset "lawyers"
    Then I should see "Franz Kafka"

  @ds_testing_table
  Scenario: A dataset record that is not published should not be shown to all users
    And an unpublished record exists for dataset "lawyers"
    When I display records for dataset "lawyers"
    Then I should not see "some content"

  @ds_testing_table
  Scenario: A dataset record that is not published should not be shown to all users even when they are guessing urls
    And an unpublished record exists for dataset "lawyers"
    When I display page 1 of sorted records for dataset "lawyers"
    Then I should not see "some content"

  @ds_testing_table
  Scenario: A dataset record that is not published should be shown to admin user
    And I am a new, authenticated user "test" with password "password"
    And an unpublished record exists for dataset "lawyers"
    When I display records for dataset "lawyers"
    Then I should see "Franz Kafka"

  @javascript
  @ds_testing_table
  Scenario: Batch editing of selected dataset records
    When I batch edit selected records for a dataset to suspended
    Then I should see a "Suspended" image

  @javascript
  @ds_testing_table
  Scenario: Batch editing all records for a dataset
    When I batch edit all records for a dataset to suspended
    Then I should see a "Suspended" image

  @javascript
  @ds_testing_table
  Scenario: Batch edit search results for a dataset
    When I batch edit search results for a dataset to suspended
    Then I should see a "Suspended" image
