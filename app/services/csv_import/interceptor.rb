module CsvImport
  InterceptSignal = Class.new(StandardError)

  class Interceptor

    attr_reader :import_file, :check_interval

    def initialize(import_file, checking_delay = 100)
      @import_file = import_file
      @called_times = 0
      @check_interval = checking_delay
    end

    def intercept
      @called_times += 1

      if @called_times % check_interval == 0
        if import_file.reload.status == 'canceled'
          raise CsvImport::InterceptSignal
        end
      end
    end
  end
end
