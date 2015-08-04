module Datanest
  class Exporter
    attr_reader :strategy

    def initialize(opts = {})
      @strategy = opts[:strategy] || :csv
    end

    def export
      prepare_workspace

      datasets.each_with_index do |dataset, index|
        puts "Dumping #{dataset.identifier.ljust(30)}(#{index+1}/#{datasets.count})"
        line_count = export_dataset(dataset)
        puts "Saved #{line_count} lines from #{dataset.identifier}"
      end
    end

    def prepare_workspace
      FileUtils.mkdir(export_path) unless File.exist?(export_path)
    end

    def export_dataset(dataset)
      columns = gather_columns(dataset)
      line_count = 0
      open_file(dataset) do |file|
        dumper_instance = dumper_klass.new(columns, file)
        dumper_instance.write_header
        dataset.each_published_records do |record|
          dumper_instance.write_record(record)
          line_count += 1
        end
      end
      line_count
    end

    private
      def gather_columns(dataset)
        dataset.visible_field_descriptions(:export)
      end

      def datasets
        DatasetDescription.all
      end

      def export_path
        @export_path ||= ENV['DATANEST_DUMP_PATH']
      end

      def dumper_klass
        @dumper_klass ||= "Datanest::Export::#{@strategy.to_s.classify}".constantize
      end

      def open_file(dataset)
        path = setup_path(dataset)

        File.open(path, "w") do |output|
          yield output
        end
      end

      def setup_path(dataset)
        FileUtils.mkdir(export_path) unless File.exist?(export_path)
        File.join(export_path, "#{dataset.identifier}-dump.#{@strategy}")
      end
  end
end
