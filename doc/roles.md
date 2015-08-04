Datanest roles
==============

Data Editor
-----------

Used in DataRepairs and to show a link to it in the menu

* edit record -> OK
* create record -> OK

* edit record metadata -> Actually edit_record is required (Added by
  Vojto) to submit the action on the dataset show page, even though
  the user needs to have the edit_record_metadata privilege to access
  the controlls (added also by Vojto)...

* edit locked record -> not used anywhere...
* import from file -> OK
* edit dataset description -> used in: DatasetCategories CRUD,
  DatasetDescription CRUD, FieldDescriptionCategory CRUD,
  FieldDescription CRUD, to show edit DatasetDescription on dataset show
  page, to show data dictionary on the menu, to show DatasetDescription
  CRUD link in the menu, to show the categories CRUD link in the menu.
  This should be a role in itself...

Same as User Manager
* view hidden fields -> isn't used anywhere
* view hidden records -> is used to stop the user when displaying the dataset show
  action and the Dataset (not fields) are not active. Is NOT used when showing an individual record...
* view hidden datasets -> is used in the API controller for the same
  purpose as view hidden records is used in the dataset show action... 
* search in hidden fields -> not used anywhere
* search in hidden records -> not used anywhere
* search in hidden datasets -> not used anywhere

Datastore manager
-----------------

The role is not used anywhere

* edit dataset description -> same as above 
* create dataset -> is needed to show the create datasetdescription link in
  the menu. Also a user needs to have this with
  edit_dataset_description to be able to create a dataset.
* destroy dataset -> is needed to perform the destroy datasetdescription
  action and to destroy datasetdescription category

User manager
------------

The role is not used anywhere

* manage users -> is used in the Users CRUD, API to create a new token
  for a different user than is requesting API access, to display links
  to the users CRUD
* block users -> not used
* grant rights -> is used to display the rights tab on user settings,
  but is not checked in the Users CRUD manage_users is still required
  for that...

Same as Data Editor
* view hidden fields
* view hidden records
* search in hidden fields
* search in hidden records

Power User
----------

Used in queries when showing dataset show and record
show to show hidden fields and records.

Misc
----

These are not linked to a role

* use_in_development -> not used
* moderate_comments -> OK used to protect Comments CRUD, show in menu
* delete_comments -> not used 

