module Dataset
  class DatastoreState
    attr_reader :dataset_description, :schema_manager

    def initialize(dataset_description, system_columns = SYSTEM_COLUMNS)
      @dataset_description = dataset_description
      @schema_manager = dataset_description.dataset_schema_manager
      @system_columns = system_columns.map(&:name).map(&:to_s)
    end

    def missing_columns
      field_description_columns - table_columns
    end

    def missing_descriptions
      table_columns - field_description_columns - @system_columns - ['id']
    end

    def table_name
      schema_manager.table_name
    end

    def table_columns
      schema_manager.columns_names
    end

    def field_description_columns
      dataset_description.field_descriptions.map(&:identifier)
    end
  end
end