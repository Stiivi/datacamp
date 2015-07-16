module Dataset
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
end