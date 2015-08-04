module CsvImport
  class Mapper
    def initialize(index_to_id_mapping, field_descriptions)
      @index_to_id_mapping = index_to_id_mapping
      @id_to_identifier_mapping = Hash[ *field_descriptions.flat_map { |field_description| [field_description.id.to_s, field_description.identifier.to_s] } ]
    end

    def build_attributes(values)
      attributes = {}

      values.each_with_index do |value, index|

        column_id = @index_to_id_mapping[index.to_s]
        next if column_id.nil?

        column_name = @id_to_identifier_mapping[column_id.to_s]
        next if column_name.nil?

        attributes[column_name] = value
      end

      attributes
    end
  end
end
