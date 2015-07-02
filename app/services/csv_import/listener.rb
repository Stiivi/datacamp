module CsvImport
  class Listener
    attr_reader :import_file, :change_storage, :change_params

    def initialize(import_file, change_storage, change_params = {})
      @import_file = import_file
      @change_storage = change_storage
      @change_params = change_params

      @saved_ids = []
      @count = 0
      @index = 0
      @unparsable_lines = []
    end

    def started
      import_file.update_attributes(count_of_imported_lines: 0, status: 'in_progress')
    end

    def skipped_line
      @index += 1
      @unparsable_lines << @index
    end

    def processed_record(record)
      @index += 1
      if record.persisted?
        @count += 1
        @saved_ids << record._record_id
      end
    end

    def intercepted
      # do nothing
    end

    def finished
      import_file.update_attributes(count_of_imported_lines: @count, status: 'success', unparsable_lines: @unparsable_lines)

      change_storage.store_batch_update(
          import_file,
          change_params.merge(
              {
                  saved_ids: @saved_ids,
                  count: @count,
              }
          )
      )
    end

    def failed
      import_file.update_attribute(:status, 'failed')
    end
  end
end
