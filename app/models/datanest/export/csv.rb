require 'csv'

module Datanest
  module Export
    class Csv
      def initialize(fields_for_export, output)
        @fields_for_export = fields_for_export
        @output = output
      end

      def write_header
        write_line(@output, @fields_for_export.map(&:identifier))
      end

      def write_record(record)
        values = record.formatted_values_for_fields(@fields_for_export)
        write_line(@output, values)
      end

      def write_line(output, values)
        output.write(CSV.generate_line(values))
      end
    end
  end
end
