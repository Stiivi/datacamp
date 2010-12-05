# Datastore Controller
#
# Copyright:: (C) 2009 Knowerce, s.r.o.
# 
# Author:: Stefan Urbanek <stefan@knowerce.sk>
# Date: Sep 2009
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# FIXME: This is obsolete, remove this file.

class DatastoreController < ApplicationController

def initialize
    @connection = DatasetRecord.connection
    @log = ApplicationLogger.new
end

def index
  @actions = 
	[
		{ :name => "Data Dictionary Check", :action => :data_dictionary_check },
		{ :name => "Bar", :action => :bar }
	]
end


def data_dictionary_check

	dataset_descriptions = DatasetDescription.all
	
	########################################################################################
	# Find all dataset descriptions, check if they have corresponding tables
	@datasets_sans_tables = []
	@undescribed_tables = []
	@conflict_tables = []

	ignored_prefixes = [ "st_", "dt_", "tmp_"]
	dataset_prefix = "ds_"
	
	# Find all tables in :data schema, and check if they have descriptions
	db_tables = all_tables
	dataset_tables = dataset_descriptions.collect { |desc| desc.identifier.to_s }

	@undescribed_tables = db_tables - (dataset_tables & db_tables)
	
	@undescribed_tables.reject! { |table|
		ignore = false
		ignored_prefixes.each { |prefix|
			if table.starts_with?(prefix) then
				ignore = true
				break
			end
		}
		ignore == true
	}

	@conflict_tables = @undescribed_tables.clone

	@conflict_tables.reject! { |table|
		not dataset_tables.include?(dataset_prefix + table)
	}
	
	# Find all columns for all tables in data descriptions, and check if they have same columns in database, and if the data types are same

	dataset_descriptions.each do |dd|

		if not @connection.table_exists? dd.identifier
			@datasets_sans_tables << dd
			next
		end

		table_desc = TableDescription.new(@connection, dd.identifier)
		column_names = table_desc.column_names
		field_names = dd.field_descriptions.collect { |fd| fd.identifier }
		
		dd.field_descriptions.each do |fd|
			# Check if exists
			if not column_names.include?(fd.identifier)
			  	@log.error "Table #{dd.identifier} is missing dataset column #{fd.identifier}"
				next
			end
		
			# Check type
			strip_type = table_desc.field_type_of_column(fd.identifier)

			if strip_type != fd.data_type.database_type
				@log.error "Type mismatch in #{dd.identifier}.#{fd.identifier}. Is #{strip_type} expected #{fd.data_type.database_type}"
			end
		end

		column_names.each do |column_name|
			# Check if exists
			if not field_names.include?(column_name) \
					and not system_columns.include?(column_name.to_sym) \
					and column_name != 'id'
			  	@log.error "Dataset #{dd.identifier} is missing description of #{column_name}"
				next
			end
		end

	end

end

#################################################
#
# Private/protected methods

protected

def all_tables
	@connection.select_all('show tables').collect { |r| r.values[0].to_s }
end

def columns_for_table(table)
	@connection.select_all("SHOW FIELDS FROM #{table}")
end

def column_names_for_table(table)
	@connection.select_all("SHOW FIELDS FROM #{table}").collect { |c| c["Field"] }
end

def system_columns
	return Dataset::Base.system_columns
end

end