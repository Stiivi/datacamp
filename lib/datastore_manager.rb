require 'sequel'

class DatastoreManager
cattr_reader :available_data_types, :dataset_table_prefix, :id_column
cattr_reader :record_metadata_columns
cattr_reader :record_statuses

attr_reader :connection
attr_accessor :schema

@@instance = nil
@@dataset_table_prefix = "ds_"
@@id_column = :_record_id

@@record_metadata_columns = [
	[:created_at, :datetime],
	[:updated_at,:datetime],
	[:created_by,:varchar],
	[:updated_by,:varchar],
	[:record_status,:varchar],
	[:quality_status,:varchar],
	[:batch_id,:integer],
	[:validity_date,:date],
	[:is_hidden,:boolean]
]

@@record_statuses = ["loaded","new","published","suspended", "deleted"]

@@available_data_types = [:string, :decimal, :integer, :date, :text]

@@field_type_map = {
		:string => :varchar
	}

def self.manager_with_default_connection
  unless @@instance
    @@instance = self.new
    @@instance.establish_rails_default_connection
  end
  @@instance
end

def establish_rails_default_connection
  establish_rails_named_connection(RAILS_ENV + "_data")
end

def establish_rails_named_connection(connection_name)
	path = Pathname.new(RAILS_ROOT)
	path = path + "config" + "database.yml"
	yaml =  YAML.load_file(path)
	
	connection_info = yaml[connection_name]
	if connection_info
		establish_connection(yaml[connection_name])	
	else
		raise "No Rails database connection named #{connection_name}"
	end
end

def establish_connection(connection_info)
    # Create database connection
    
    @connection_info = connection_info

    @connection = Sequel.mysql(connection_info["database"],
            :user => connection_info["username"] || "root",
            :password => connection_info["password"], 
            :host => connection_info["host"],
            :encoding => 'utf8'
            )

    Sequel::MySQL.default_charset = 'utf8'

	if @connection.nil?
		raise "Unable to establish database connection"
	end

	@schema = connection_info["schema"]
end

def extract_dataset_into_file(identifier, file, options = nil)
	path = Pathname(file)
	dirname = path.dirname
	
	# Notes:
	# * file will be overwritten
	
	dirname.mkpath

end

def dataset_exists?(dataset)
	return datasets.includes?(dataset)
end


def dataset_fields(dataset)
	table = table_for_dataset(dataset)
	metadata = @@record_metadata_columns.collect { |col| col[0]}
	fields = @connection[table].columns
	fields = fields - metadata
	fields.delete(@@id_column)
	
	return fields
end

def dataset_information(dataset)
	info = {}
	
	info[:count] = 9999
end

def dataset_field_types(dataset)
	table = table_for_dataset(dataset)
	schema = @connection.schema(table)
	metadata = @@record_metadata_columns.collect { |col| col[0]}

	schema = schema.select { | field | 
								not metadata.include?(field[0]) and
									field[0] != @@id_column  }
	schema = schema.collect { |field| [field[0], field[1][:type]] }
	return schema
end

def dataset_field_type(dataset, field)
  data_types = self.dataset_field_types(dataset)
  data_types_hash = Hash[*data_types.flatten]
  data_types_hash[field.to_sym]
end

def add_dataset_field(dataset, field, type)
	table = table_for_dataset(dataset)
	mapped_type = @@field_type_map[type.to_sym]

	if mapped_type
		type = mapped_type
	end
	@connection.add_column(table, field, type)
end

def set_dataset_field_type(dataset, field, type)
	table = table_for_dataset(dataset)

	mapped_type = @@field_type_map[type.to_sym]
	if mapped_type
		type = mapped_type
	end
	@connection.set_column_type(table, field, type)
end

def rename_dataset_field(dataset, field, new_name)
	table = table_for_dataset(dataset)
	@connection.rename_column(table, field, new_name)
end

def remove_dataset_field(dataset, field)
	table = table_for_dataset(dataset)
	@connection.drop_column(table, field)
end

def datasets
	# FIXME: Does not work on oracle
	data = @connection[:information_schema__tables]
	data = data.filter(:table_schema => @schema)

	tables = Array.new
	puts data.sql
	data.all do |row|
		tables << row[:TABLE_NAME]
	end
	tables = tables.select { |table| table =~ /^#{@@dataset_table_prefix}/ }
	tables = tables.collect { |table| table.sub(/^#{@@dataset_table_prefix}/,"") }
	return tables
end

def dataset_exists?(identifier)
	return datasets.include?(identifier)
end

def create_dataset(identifier)
	dataset_table = table_for_dataset(identifier)

	# FIXME: is this charset option portable (for example to oracle)?
	@connection.create_table(dataset_table, :options => 'DEFAULT CHARSET=utf8') do
		primary_key @@id_column
		@@record_metadata_columns.each do |column|
			column column[0], column[1]
		end
	end
end

def create_dataset_as_copy_of_table(table, dataset_name = nil)
	if not dataset_name
		dataset_name = table
	end
	
	dataset_table = table_for_dataset(table)
	
	if @connection.table_exists?(dataset_table)
		raise "Dataset #{dataset_name} already exists"
	end

	# 1. Perform checks
	columns = @connection[table.to_sym].columns
	metadata = @@record_metadata_columns.collect { |col| col[0]}

	existing_metadata_columns = metadata & columns
	puts "HERE->> (#{existing_metadata_columns.join(",")})"

	if not existing_metadata_columns.empty?
		raise "Table #{table} contains columns with same name as " +
				"metadata columns (#{existing_metadata_columns.join(",")})"
	end
	# 2. copy table

	statement = "CREATE TABLE #{dataset_table} AS SELECT * FROM #{table}"
	connection << statement
	
	# 3. create dataset columns
	fix_dataset_metadata(dataset_name)
end

def check_missing_dataset_metadata(dataset)
	dataset_table = table_for_dataset(dataset)
	
	columns = @connection[dataset_table].columns
	metadata = @@record_metadata_columns.collect { |col| col[0]}

	missing_metadata = @@record_metadata_columns.select { |mcolumn|
				not columns.include?(mcolumn[0])
		}

	if not columns.include?(@@id_column)
		missing_metadata << @@id_column
	end
	
	return missing_metadata
end

def fix_dataset_metadata(dataset)
	dataset_table = table_for_dataset(dataset)
	missing_metadata = check_missing_dataset_metadata(dataset)

	missing_id = false
	if missing_metadata.include?(@@id_column)
		missing_id = true
		missing_metadata.delete(@@id_column)
	end
	
	# FIXME: handle missing/misconfigured ID as special case
	@connection.alter_table dataset_table do
		if missing_id
			add_primary_key @@id_column, :auto_increment => true
		end

		missing_metadata.each do |column|
			add_column column[0], column[1]
		end
	end
	
	# FIXME: fill metadata columns here or not?
end

def table_for_dataset(dataset)
  # FIXME:
  # return "#{@@schema}__#{@@dataset_table_prefix}#{dataset.to_s}".to_sym
  return "#{@@dataset_table_prefix}#{dataset.to_s}".to_sym
end

# def initialize_datastore

# def create_metadata_for_dataset (dataset identifier)
# def create_dataset_table_from_description
# def create_description_form_table
# def table_for_dataset
# def initialize_dataset
# def upgrade_dataset


end
