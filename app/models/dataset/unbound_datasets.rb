module Dataset
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
end
