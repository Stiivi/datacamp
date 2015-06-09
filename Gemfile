source 'http://rubygems.org'

gem 'rails', '3.2.18'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier',     '>= 1.0.3'

  gem 'therubyracer'
end

gem 'mysql2'

gem 'jquery-rails'

gem 'haml-rails', '~> 0.4.0' # version for rails 3
gem "RedCloth", :require => "redcloth"

gem 'globalize', '~> 3.1.0'
gem 'paperclip'
gem 'recaptcha', :require => "recaptcha/rails", :git => 'git://github.com/ambethia/recaptcha.git'
gem 'spawn'
gem 'will_paginate'
gem 'delayed_job'
gem 'nokogiri'
gem 'riddle', '>= 1.3.3'
gem 'typhoeus', '~> 0.5.0'
gem 'delayed_job_admin'
gem 'whenever', :require => false
gem 'newrelic_rpm'
gem 'thinking-sphinx', '>= 2.0.2', :require => 'thinking_sphinx'
gem "actionmailer_inline_css", :git => 'https://github.com/ndbroadbent/actionmailer_inline_css.git', ref: 'a9c939f94c424a0b9e3a92bb1b280141c87f6195'
gem 'gabba'
gem 'rollbar'

gem 'unicorn'
gem 'rack-rewrite'

gem 'roadie'
gem 'mechanize'
gem 'thin'

# this gems should be removed in future
gem 'dynamic_form'

# bundle with '--without macosx' if you are not not a good system :)
group :developemnt, :macosx do
  # This branch is being used because of a problem with the gcc-only installer https://github.com/kennethreitz/osx-gcc-installer not being able to coompile it.
  gem 'rb-fsevent', :git => 'git://github.com/ttilley/rb-fsevent.git', :branch => 'pre-compiled-gem-one-off', :require => :false
  gem 'growl'
end

group :development do
  gem "mailcatcher"

  gem 'rails_best_practices'
  # Deploy with Capistrano multistage
  gem 'capistrano', '~> 2'
  gem 'capistrano-ext'
  gem 'rvm'
  gem 'letter_opener'

  gem "bullet"
end

group :development, :test do
  gem 'cucumber-rails', require: false
  gem 'rspec-activemodel-mocks'
  gem 'rspec-collection_matchers'
  gem 'rspec-rails', '~> 2.14'
  gem 'capybara'
  gem 'poltergeist'
  gem 'database_cleaner'
  gem 'launchy'    # So you can do Then show me the page
  gem 'factory_girl_rails'
  gem 'vcr', '~> 2.9.0'
  gem 'fakeweb'
  gem 'pry'
  gem 'simplecov', require: false
end

group :test do
  gem 'codeclimate-test-reporter', require: nil
  gem 'capybara-screenshot'
end
