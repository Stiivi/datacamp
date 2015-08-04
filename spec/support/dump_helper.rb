module DumpHelper
  def dataset_dump_path
    ENV['DATANEST_DUMP_PATH']
  end

  def create_dump_folder
    FileUtils.mkdir_p(dataset_dump_path)
  end

  def drop_dump_folder
    FileUtils.rm_rf(dataset_dump_path)
  end

  def export_dump_for_dataset(dataset)
    Datanest::Exporter.new.export_dataset(dataset)
  end
end

RSpec.configure do |config|
  config.include DumpHelper

  config.before(:each) do
    if RSpec.current_example.metadata[:use_dump]
      create_dump_folder
    end
  end

  config.after(:each) do
    drop_dump_folder if RSpec.current_example.metadata[:use_dump]
  end
end
