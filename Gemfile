source 'http://rubygems.org'

ruby '2.2.2'
gem 'rails', '3.2.22'

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

gem 'globalize', '~> 3.1.0' # version for rails 3
gem 'paperclip'
gem 'recaptcha', :require => 'recaptcha/rails'
gem 'will_paginate'
gem 'delayed_job'
gem 'nokogiri'
gem 'typhoeus'
gem 'delayed_job_admin'
gem 'whenever', :require => false
gem 'newrelic_rpm'
gem 'thinking-sphinx'
gem 'actionmailer_inline_css'
gem 'gabba'
gem 'rollbar'

gem 'unicorn'
gem 'raindrops', '~> 0.13.0' # for unicorn, special version for ruby 2.2.2
gem 'rack-rewrite'

gem 'roadie', '~> 2.4.0' # version for rails 3
gem 'mechanize'
gem 'thin'

# this gems should be removed in future
gem 'dynamic_form'
gem 'test-unit', '~> 3.0' # ruby 2.2.2 needs this for rails 3.2

group :development do
  gem 'mailcatcher', '~> 0.5.0' # version for rails 3

  gem 'rails_best_practices'
  # Deploy with Capistrano multistage
  gem 'capistrano', '~> 2'
  gem 'capistrano-ext'
  gem 'letter_opener'

  gem 'bullet'
end

group :development, :test do
  gem 'cucumber-rails', require: false
  gem 'rspec-activemodel-mocks'
  gem 'rspec-collection_matchers'
  gem 'rspec-rails', '~> 2.14'
  gem 'capybara'
  gem 'poltergeist'
  gem 'database_cleaner'
  gem 'launchy'
  gem 'factory_girl_rails'
  gem 'vcr'
  gem 'fakeweb'
  gem 'pry'
  gem 'simplecov', require: false
end

group :test do
  gem 'codeclimate-test-reporter', require: nil
  gem 'capybara-screenshot'
end
