module CsvImport
  class Record
    attr_reader :model, :mapper, :import_file

    def initialize(model, mapper, import_file)
      @mapper = mapper
      @model = model
      @import_file = import_file
    end

    def store(values)
      attributes = mapper.build_attributes(values)

      model.create(
          attributes.merge(
              {
                  record_status: Dataset::RecordStatus.find(:new),
                  is_part_of_import: true,
                  batch_id: import_file.id
              }
          )
      )
    end
  end
end
