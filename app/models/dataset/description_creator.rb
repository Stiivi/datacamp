module Dataset
  class DescriptionCreator
    def self.create_description_for_table(identifier)
      DatasetDescription.create!(
          identifier: identifier,
          title: identifier.humanize.titleize
      )
    end

    def self.create_description_for_column(dataset_description, column)
      # FIXME: not localizable!
      # FIXME: we should create also type!
      FieldDescription.create!(
          identifier: column.name,
          title: column.name.to_s.humanize.titleize,
          category: "Other",
          dataset_description: dataset_description
      )
    end
  end
end