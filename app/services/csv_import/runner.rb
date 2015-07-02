module CsvImport
  class Runner
    attr_reader :csv_file, :record_storage, :listener, :interceptor

    def initialize(csv_file, record_storage, listener, interceptor)
      @csv_file = csv_file
      @record_storage = record_storage
      @listener = listener
      @interceptor = interceptor
    end

    def run
      listener.started

      csv_file.parse_all_lines do |row_values|

        if row_values.nil?
          listener.skipped_line
          next
        end

        record = record_storage.store(row_values)
        listener.processed_record(record)

        interceptor.intercept
      end

      listener.finished
    rescue CsvImport::InterceptSignal
      listener.intercepted
    rescue EOFError
      listener.failed
    end
  end
end
