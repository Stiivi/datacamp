require 'thinking_sphinx/test'

module FulltextHelpers
  def prepare_sphinx_search
    FileUtils.rm_rf 'db/sphinx/test'
    FileUtils.rm 'config/test.sphinx.conf', :force => true
    FileUtils.mkdir_p 'db/sphinx/test'

    ThinkingSphinx::Test.init
    sleep 0.1 until index_finished?

    SphinxDatasetIndex.define_indices_for_all_datasets
    ThinkingSphinx::Test.start_with_autostop
  end

  def index_finished?
    Dir[Rails.root.join(ThinkingSphinx::Test.config.indices_location, '*.{new,tmp}*')].empty?
  end
end

RSpec.configure do |config|
  config.include FulltextHelpers
end
