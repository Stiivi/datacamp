module Dataset
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