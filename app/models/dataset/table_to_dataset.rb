module Dataset
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
end