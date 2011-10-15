Feature: Datasets with relations

  In order to be able to publish data with database realtion
  As an administrator
  I want to be able to publish a dataset that has a relation defined and displays fields from the related table
  
  Background:
    Given a published dataset "testings"
    And a published dataset "relation_testings"
    And I am a new, authenticated user "test" with password "password"
  
  Scenario: Publish a table with a has_many relationship
    And a published record with "some content" exists for dataset "testings"
    And a published record with "some content2" exists for relation dataset "relation_testings"
    When I set up a "has_many" relationship on "testings" to "relation_testings"
    And I display the first record for dataset "testings"
    Then I should see "some content"
    And I should see "some content2"
  
  Scenario: Publish a table with a has_many :through relationship
  
  Scenario: Publish a table with a belongs_to relationship
    And a published record with "some content" exists for dataset "testings"
    And a published record with "some content2" exists for relation dataset "relation_testings"
    When I set up a "belongs_to" relationship on "relation_testings" to "testings"
    And I display the first record for dataset "relation_testings"
    Then I should see "some content"
    And I should see "some content2"