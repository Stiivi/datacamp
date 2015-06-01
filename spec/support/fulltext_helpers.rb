require 'thinking_sphinx/test'

module FulltextHelpers
  def prepare_sphinx_search
    FileUtils.rm_rf 'db/sphinx/test'
    FileUtils.rm 'config/test.sphinx.conf', :force => true
    FileUtils.mkdir_p 'db/sphinx/test'

    ThinkingSphinx::Test.init
    SphinxDatasetIndexer.index_all_datasets
    ThinkingSphinx::Test.start_with_autostop
  end
end

RSpec.configure do |config|
  config.include FulltextHelpers
end
