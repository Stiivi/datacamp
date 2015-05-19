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
end

RSpec.configure do |config|
  config.include DatabaseCleanerHelper

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.after(:suite) do
  end

  config.before(:each) do
    DatabaseCleaner.strategy = get_cleaner_strategy(example)
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end