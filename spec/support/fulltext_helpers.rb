require 'thinking_sphinx/test'

module FulltextHelpers
  def prepare_sphinx_search
    SphinxDatasetIndexer.index_all_datasets
    start_search_engine
    index_search_engine
  end

  def start_search_engine
    ThinkingSphinx::Test.start_with_autostop
  end

  def stop_search_engine
    ThinkingSphinx::Test.stop
  end

  def index_search_engine
    report = ThinkingSphinx::Test.index
    if report =~ /error/i
      puts report
    end
    sleep(0.6)
  end
end

RSpec.configure do |config|
  config.include FulltextHelpers

  config.before(:each) do
    if RSpec.current_example.metadata[:sphinx]
      FileUtils.mkdir_p 'db/sphinx/test'
    end
  end

  config.after(:each) do
    if RSpec.current_example.metadata[:sphinx]
      stop_search_engine
      FileUtils.rm_rf 'db/sphinx/test'
      FileUtils.rm 'config/test.sphinx.conf'
    end
  end
end