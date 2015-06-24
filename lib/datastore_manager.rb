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
  [:created_by,:string],
  [:updated_by,:string],
  [:record_status,:string],
  [:quality_status,:string],
  [:batch_id,:integer],
  [:validity_date,:date],
  [:is_hidden,:boolean]
]

@@record_statuses = ["loaded","new","published","suspended", "deleted", 'morphed']

@@available_data_types = [:string, :integer, :date, :text, :decimal, :boolean]

def self.manager_with_default_connection
  unless @@instance
    @@instance = self.new
    @@instance.establish_connection
  end
  @@instance
end

def establish_connection
  @connection = Dataset::DatasetRecord.connection
end

# returns specific columns for dataset table in format:
#   [[:name, :string], [:address, :string]]
def dataset_field_types(dataset)
  table = table_for_dataset(dataset)

  table_columns = @connection.columns(table)

  metadata_columns = @@record_metadata_columns.collect { |col| col[0] }
  metadata_columns << @@id_column

  custom_columns = table_columns.reject { |column| metadata_columns.include?(column.name.to_sym) }
  custom_columns.map{ |column| [column.name.to_sym, column.type] }
end

def dataset_field_type(dataset, field)
  @data_types = self.dataset_field_types(dataset)
  data_types_hash = Hash[*@data_types.flatten]
  data_types_hash[field.to_sym]
end

def add_dataset_field(dataset, field, type)
  table = table_for_dataset(dataset)
  @connection.add_column(table, field, type)
end

def set_dataset_field_type(dataset, field, type)
  table = table_for_dataset(dataset)
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
  "#{@@dataset_table_prefix}#{dataset.to_s}".to_sym
end

end
