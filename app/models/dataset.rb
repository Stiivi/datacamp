module Dataset
  Column = Struct.new(:name, :type)

  COLUMN_TYPES = [:string, :integer, :date, :text, :decimal, :boolean]

  SYSTEM_COLUMNS = [
      Column.new(:created_at,     :datetime),
      Column.new(:updated_at,     :datetime),
      Column.new(:created_by,     :string),
      Column.new(:updated_by,     :string),
      Column.new(:record_status,  :string),
      Column.new(:quality_status, :string),
      Column.new(:batch_id,       :integer),
      Column.new(:validity_date,  :date),
      Column.new(:is_hidden,      :boolean),
  ]

  DATASET_TABLE_PREFIX = 'ds_'

  SYSTEM_TABLES = [
      'dc_relations', 'dc_updates', 'schema_migrations'
  ]

  CONNECTION = Dataset::DatasetRecord.connection

  class UnboundDatasets
    attr_reader :system_tables, :connection

    def initialize(system_tables = SYSTEM_TABLES, connection = CONNECTION)
      @connection = connection
      @system_tables = system_tables
    end

    def all
      connection.tables.reject do |table_name|
        system_tables.include?(table_name) || table_name =~ Regexp.new("^#{DATASET_TABLE_PREFIX}")
      end
    end
  end

  class Status
    attr_reader :status

    def initialize(values)
      @status = Set.new(values)
    end

    def all
      status
    end

    def find(name)
      if status.include?(name.to_s)
        name.to_s
      else
        raise KeyError, "status: #{name} not found"
      end
    end
  end

  RecordStatus = Status.new(
      ['absent', 'loaded', 'new', 'published', 'suspended', 'deleted', 'morphed']
  )

  module Naming
    extend self

    def model_class_name(dataset_description)
      "#{prefix}#{dataset_description.identifier}".classify
    end

    def full_model_class_name(dataset_description)
      "Kernel::#{model_class_name(dataset_description)}"
    end

    def table_name(dataset_description)
      table_name_from_identifier(dataset_description.identifier)
    end

    def table_name_from_identifier(identifier)
      if identifier.start_with?(prefix)
        identifier
      else
        prefix + identifier
      end
    end

    def prefix
      DATASET_TABLE_PREFIX
    end

    def association_name(dataset_description, morphed = false)
      suffix = morphed ? "_morphed" : ""

      :"#{prefix}#{dataset_description.identifier.pluralize}#{suffix}"
    end

    def association_name_to_identifier(association_name)
      association_name.to_s.gsub(/#{prefix}|_morphed/,'').pluralize
    end
  end

  class DescriptionCreator
    def self.create_description_for_table(identifier)
      DatasetDescription.create!(
          identifier: identifier,
          title: identifier.humanize.titleize
      )
    end

    def self.create_description_for_column(dataset_description, column)
      # FIXME: not localizable!
      # FIXME: we should create also type!
      FieldDescription.create!(
          identifier: column.name,
          title: column.name.to_s.humanize.titleize,
          category: "Other",
          dataset_description: dataset_description
      )
    end
  end

  class TableDescriber
    attr_reader :identifier, :schema_manager, :description_creator, :system_columns

    def initialize(identifier, schema_manager, description_creator = DescriptionCreator, system_columns = SYSTEM_COLUMNS)
      @identifier = identifier
      @schema_manager = schema_manager
      @description_creator = description_creator
      @system_columns = system_columns
    end

    def describe
      dataset_description = description_creator.create_description_for_table(identifier)

      schema_manager.columns.each do |column|
        next if ignore_columns.include?(column.name)

        description_creator.create_description_for_column(dataset_description, column)
      end

      dataset_description
    end


    private

    def ignore_columns
      @ignore_columns ||= system_columns.map(&:name) + [:_record_id]
    end
  end

  class TableToDataset
    Result = Struct.new(:errors, :dataset_description) do
      def valid?
        errors.blank?
      end
    end

    def self.execute(table_identifier, description_identifier = nil)
      description_identifier ||= table_identifier

      schema_manager = Dataset::SchemaManager.new(Dataset::Naming.table_name_from_identifier(table_identifier))
      transformer = TableTransformer.new(schema_manager)

      if transformer.transform_from(table_identifier)
        dataset_description = TableDescriber.new(
            description_identifier,
            schema_manager
        ).describe

        Result.new([], dataset_description)
      else
        Result.new(transformer.errors, :missing_description)
      end
    end
  end

  class TableCreator
    attr_reader :dataset_description, :schema_manager, :system_columns, :errors

    def initialize(dataset_description, schema_manager, system_columns = SYSTEM_COLUMNS)
      @dataset_description = dataset_description
      @schema_manager = schema_manager
      @system_columns = system_columns
    end

    def create
      @errors = []

      if schema_manager.table_exists?
        add_error "Table '#{dataset_description.identifier}' already exists."
        return false
      end

      schema_manager.create_table
      schema_manager.set_up_primary_key

      add_system_column
      add_columns_from_fields

      errors.blank?
    end

    private

    def add_error(error)
      @errors << error
    end

    def add_system_column
      system_columns.each do |column|
        if schema_manager.has_column?(column.name)
          add_error "System column '#{column.name}' already exists"
        else
          schema_manager.add_column(column.name, column.type)
        end
      end
    end

    def add_columns_from_fields
      dataset_description.field_descriptions.each do |field_description|
        schema_manager.add_column(field_description.identifier, field_description.data_type_with_default)
      end
    end
  end

  class TableTransformer
    attr_reader :schema_manager, :system_columns, :errors

    def initialize(schema_manager, system_columns = SYSTEM_COLUMNS)
      @schema_manager = schema_manager
      @system_columns = system_columns
    end

    def transform_from(table_identifier)
      @errors = []

      unless schema_manager.table_exists?(table_identifier)
        add_error "Can't transform table: There's no #{table_identifier} table."

        return false
      end

      schema_manager.rename_table_from(table_identifier) unless table_identifier == schema_manager.table_name
      schema_manager.set_up_primary_key

      add_system_columns

      true
    end

    private

    def add_error(error)
      @errors << error
    end

    def add_system_columns
      system_columns.each do |column|
        schema_manager.add_column(column.name, column.type) unless schema_manager.has_column?(column.name)
      end
    end
  end

  class TableSchema
    attr_reader :table_name, :connection

    def initialize(table_name, connection = CONNECTION)
      @table_name = table_name
      @connection = connection
    end

    def columns
      connection.columns(table_name)
    end

    def columns_names
      return [] unless table_exists?

      columns.map(&:name).map(&:to_s)
    end

    def has_column?(name)
      columns_names.include?(name.to_s)
    end

    def table_exists?(name = nil)
      name ||= table_name
      connection.tables.include?(name.to_s)
    end
  end

  class SchemaManager < TableSchema
    def create_table
      connection.create_table(table_name, options: 'DEFAULT CHARSET=utf8', primary_key: '_record_id') {}
    end

    def rename_table_from(current_table_name)
      connection.rename_table(current_table_name, table_name)
    end

    def set_up_primary_key
      disable_old_primary_key if has_column?('id')
      add_primary_key unless has_column?('_record_id')
    end

    def add_column(column_name, type, options = {})
      connection.add_column(table_name, column_name, type, options)
    end

    def rename_column(column_name, new_column_name)
      connection.rename_column(table_name, column_name, new_column_name)
    end

    def change_column_type(column_name, type)
      connection.change_column(table_name, column_name, type)
    end

    def remove_column(column_name)
      connection.remove_column(table_name, column_name)
    end

    private

    def disable_old_primary_key
      connection.change_column table_name, :id, :integer, auto_increment: false, null: true
      begin
        connection.execute "ALTER TABLE #{table_name} DROP PRIMARY KEY"
      rescue
      end
    end

    def add_primary_key
      connection.add_column table_name, :_record_id, :primary_key
    end
  end
end
