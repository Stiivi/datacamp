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
    # set up multiple connection for cleaning
    DatabaseCleaner[:active_record, {connection: :test}]
    DatabaseCleaner[:active_record, {connection: :test_data}]
    DatabaseCleaner[:active_record, {connection: :test_staging}]

    DatabaseCleaner.clean_with(:truncation)
  end

  config.after(:suite) do
  end

  config.before(:each) do
    strategy = get_cleaner_strategy(example)
    DatabaseCleaner.strategy = strategy
    if strategy == :truncation
      DatabaseCleaner[:active_record, {connection: :test_data}].strategy = strategy, {cache_tables: false}
    end
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end