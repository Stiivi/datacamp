# -*- encoding : utf-8 -*-

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

# This is here because the vcr library saves its cassettes in yaml format and psych throws segfaults if the string being saved has an invalid utf-8 character in it.
# Can be removed when the issue is resolved https://github.com/myronmarston/vcr/issues/74
VCR::YAML = ::YAML

VCR.config do |c|
  c.cassette_library_dir = "#{Rails.root}/spec/fixtures/vcr_cassettes"
  c.stub_with :typhoeus
  c.default_cassette_options = { :record => :once }
end

RSpec.configure do |config|

  config.infer_spec_type_from_file_location!

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # Put deprecation warnings to file
  config.deprecation_stream = 'log/deprecations.log'

  config.include(DatasetHelpers)
end
