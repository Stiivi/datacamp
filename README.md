# DataCamp

[![Build Status](https://travis-ci.org/fairplaysk/datacamp.svg?branch=chore%2Ffeature-tests)](https://travis-ci.org/fairplaysk/datacamp)
[![Dependency Status](https://gemnasium.com/fairplaysk/datacamp.svg)](https://gemnasium.com/fairplaysk/datacamp)
[![Code Climate](https://codeclimate.com/github/fairplaysk/datacamp/badges/gpa.svg)](https://codeclimate.com/github/fairplaysk/datacamp)
[![Test Coverage](https://codeclimate.com/github/fairplaysk/datacamp/badges/coverage.svg)](https://codeclimate.com/github/fairplaysk/datacamp/coverage)

## ABOUT

Datacamp is a Web application for publishing, searching and managing data
in form of datasets.

## QUICKSTART

````
bin/setup
foreman start
````

## DEPLOYMENT

1. Provision a server using the provided ansible scripts.

2. On the server, set up application environment in `.bashrc`. Start by copying
   all variables from `.env` and change them as needed. It is important that

   - the variables are exported to subprocesses, i.e., (unlike in `.env`) start
     each line with export. For example `export DATANEST_MYSQL_PASSWORD=pass`.
   - the exports are placed at the very top of the `.bashrc` file, before the
     check that skips loading the rest of the file in non-interactive session
     (that means both capistrano and passenger)

````
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

export DATANEST_MYSQL_HOST=localhost
export DATANEST_MYSQL_PORT=3306
# [more exports ...]

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# [rest of the .bashrc]
````

3. For the first time, run `cap production deploy:cold`. This will create
   databases and import schemas. This should only be called once and in the
   first deploy. Otherwise run `cap production deploy`.

4. Optionally, to import database dumps, first download them on your
   development machine and run `cap production deploy:import_dump
   DUMP=path/to/datanest_data_dump.sql.gz`. The file will be gzipped
   automatically if not already. Make sure that the dump name start with
   `datanest_$DB` as the name format is used to extract the database name.

## LICENSE
(see COPYING file for full license text)


This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.


## AUTHORS

* Michal Olah <olahmichal(at)gmail.com> - main application programming
* Stefan Urbanek <stefan@knowerce.sk> - architecture design, back-end programming
* Vojto Rinik <vojto@rinik.net> - application programming
