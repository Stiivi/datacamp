Feature: Datasets with relations

  In order to be able to publish data with database realtion
  As an administrator
  I want to be able to publish a dataset that has a relation defined and displays fields from the related table

  Background:
    Given a published dataset "testing"
    And a published dataset "testing2"
    And I am a new, authenticated user "test" with password "password"
  
  Scenario: Publish a table with a has_many relationship
    And a published record with "some content" exists for dataset "testing"
    And a published record with "some content2" exists for dataset "testing2"
    When I set up a has_many relationship on "testing" to "testing2" with foreign_key "relation_id"
    And I display the first record for dataset "testing"
    Then I should see "some content"
    And I should see "some content2"

  Scenario: Publish a table with a has_many :through relationship

  Scenario: Publish a table with a belongs_to relationship