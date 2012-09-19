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
* edit dataset description
* create dataset
* destroy dataset

User manager
------------
* manage users
* block users
* grant rights
* power user

Same as Data Editor
* view hidden fields
* view hidden records
* search in hidden fields
* search in hidden records
