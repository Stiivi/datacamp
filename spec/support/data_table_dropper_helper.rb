# Drops tables that where created in test to ensure each test has the same state of the world
class TableDropper
  def initialize(connection, model_name_space = Object)
    @connection = connection
    @model_name_space = model_name_space
  end

  def store_tables
    @tables = Set.new(@connection.tables)
  end

  def drop_new_tables
    @connection.tables.each do |table_name|
      if @tables.exclude?(table_name)
        remove_model_class(table_name)
        @connection.drop_table(table_name)
      end
    end
  end

  private

  def remove_model_class(table_name)
    dataset_model = :"#{table_name.singularize.camelcase}"
    return unless @model_name_space.send(:const_defined?, dataset_model)

    @model_name_space.send(:remove_const, dataset_model)
  end
end

module DataTableDropperHelper
  def self.dropper
    @dropper ||= TableDropper.new(Dataset.connection, Kernel)
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
