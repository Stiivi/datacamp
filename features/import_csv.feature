Feature: Import files

  In order to be able to import data into datasets
  As a data editor
  Should be able to upload a file, match the contents to fields and run the import

  Background:
    Given I am a new, authenticated user "test" with password "password"
    Given two published datasets with data exist

  @cleanup_files_after
  Scenario: Upload a file
    When I upload a new file
    Then I should see "File is ready to be imported."

  @cleanup_files_after
  Scenario: Match the contents
    When I upload a new file
    Then columns should be matched based what is in the file header

  @cleanup_files_after
  Scenario: Run the import
    When I start an import
    Then I should see "Importing wasn't triggered yet."

