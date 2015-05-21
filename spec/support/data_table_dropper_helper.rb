# Drops tables that where created in test to ensure each test has the same state of the world
class TableDropper
  def initialize(connection)
    @connection = connection
  end

  def store_tables
    @tables = Set.new(@connection.tables)
  end

  def drop_new_tables
    @connection.tables.each do |table_name|
      @connection.drop_table(table_name) if @tables.exclude?(table_name)
    end
  end
end

module DataTableDropperHelper
  def self.dropper
    @dropper ||= TableDropper.new(Dataset::DatasetRecord.connection)
  end
end

RSpec.configure do |config|

  config.before(:suite) do
    DataTableDropperHelper.dropper.store_tables
  end

  config.after(:each) do
    DataTableDropperHelper.dropper.drop_new_tables
  end
end