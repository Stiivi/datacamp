module Dataset
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

end