class DatastoreManager
cattr_reader :available_data_types, :dataset_table_prefix, :id_column
cattr_reader :record_metadata_columns
cattr_reader :record_statuses

attr_reader :connection

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
  @connection.change_column(table, field, type)
end

def table_for_dataset(dataset)
  "#{@@dataset_table_prefix}#{dataset.to_s}".to_sym
end

end
