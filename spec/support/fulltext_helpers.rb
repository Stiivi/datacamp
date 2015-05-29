require 'thinking_sphinx/test'

module FulltextHelpers
  def prepare_sphinx_search
    stop_search_engine
    SphinxDatasetIndexer.index_all_datasets
    start_search_engine
    index_search_engine
  end

  def start_search_engine
    puts ThinkingSphinx::Test.start_with_autostop
  end

  def stop_search_engine
    puts ThinkingSphinx::Test.stop
  end

  def index_search_engine
    puts ThinkingSphinx::Test.index
    sleep(0.6)
  end
end

RSpec.configure do |config|
  config.include FulltextHelpers

  config.after(:all) do
    stop_search_engine
  end
end