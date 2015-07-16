module Dataset
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
end