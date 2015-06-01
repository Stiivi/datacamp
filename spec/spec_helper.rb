# -*- encoding : utf-8 -*-
if ENV["COVERAGE"] == "1"
  require 'simplecov'
  SimpleCov.start 'rails'
end

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

FakeWeb.allow_net_connect = %r[^https?://(codeclimate\.com/)|(127\.0\.0\.1)|(localhost)]

require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist

RSpec.configure do |config|
  config.filter_run focus: true
  config.filter_run_excluding skip: true
  config.run_all_when_everything_filtered = true

  config.infer_spec_type_from_file_location!

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # Put deprecation warnings to file
  config.deprecation_stream = 'log/deprecations.log'

  config.include(DatasetHelpers)
end

