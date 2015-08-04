module Dataset
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
end