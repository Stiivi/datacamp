module DatabaseCleanerHelper
  def transaction_tests_from_folders
    [
        "./spec/lib",
        "./spec/models",
        "./spec/services",
        "./spec/mailers",
        "./spec/helpers",
        "./spec/decorators",
    ]
  end

  def get_cleaner_strategy(example)
    if (transaction_tests_from_folders.any?{ |path| example.location.start_with? path } || example.metadata[:quick_db]) && example.metadata[:slow_db].blank?
      :transaction
    else
      :truncation
    end
  end

  def self.connection_names
    [
        :test,
        :test_data,
        :test_staging,
    ]
  end
end

RSpec.configure do |config|
  config.include DatabaseCleanerHelper

  config.before(:suite) do
    DatabaseCleanerHelper.connection_names.each do |connection|
      DatabaseCleaner[:active_record, {connection: connection}].clean_with(:truncation)
    end
  end

  config.after(:suite) do
  end

  config.before(:each) do
    DatabaseCleanerHelper.connection_names.each do |connection|
      DatabaseCleaner[:active_record, {connection: connection}].strategy = get_cleaner_strategy(example)
      DatabaseCleaner[:active_record, {connection: connection}].start

      puts "#{connection} strategy: #{DatabaseCleaner[:active_record, {connection: connection}].strategy} start"

    end
  end

  config.after(:each) do
    DatabaseCleanerHelper.connection_names.each do |connection|
      DatabaseCleaner[:active_record, {connection: connection}].clean
      puts "#{connection} strategy: #{DatabaseCleaner[:active_record, {connection: connection}].strategy} clean"
    end
  end
end