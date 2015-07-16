module Dataset
  class DescriptionCreator
    def self.create_description_for_table(identifier)
      DatasetDescription.create!(
          identifier: identifier,
          title: identifier.humanize.titleize
      )
    end

    def self.create_description_for_column(dataset_description, column, supported_types = COLUMN_TYPES)
      raise Dataset::UnsupportedType, "type: #{column.type} is not supported" if supported_types.exclude?(column.type)

      # FIXME: not localizable!
      FieldDescription.create!(
          identifier: column.name,
          title: column.name.to_s.humanize.titleize,
          category: "Other",
          data_type: column.type,
          dataset_description: dataset_description
      )
    end
  end
end