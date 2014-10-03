source 'http://rubygems.org'

gem 'rails', '3.1.12'

group :assets do
  gem 'sass-rails',   '~> 3.1.7'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier',     '>= 1.0.3'

  gem 'therubyracer'
end

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2'

gem 'jquery-rails'

gem 'haml-rails'
gem "RedCloth", :require => "redcloth"
gem "sequel"

gem 'globalize3'
gem 'paperclip'
gem 'recaptcha', :require => "recaptcha/rails", :git => 'git://github.com/ambethia/recaptcha.git'
gem 'spawn'
gem 'validation_reflection'
gem 'will_paginate'
#gem 'restful-authentication', :git => 'git://github.com/Satish/restful-authentication.git', :branch => 'rails3'
gem 'delayed_job'
gem 'nokogiri'
gem 'riddle', '>= 1.3.3'
gem 'typhoeus'
gem 'delayed_job_admin'
gem 'whenever', :require => false
gem 'newrelic_rpm'
gem 'thinking-sphinx', '>= 2.0.2', :require => 'thinking_sphinx'
gem "actionmailer_inline_css", :git => 'https://github.com/ndbroadbent/actionmailer_inline_css.git', ref: 'a9c939f94c424a0b9e3a92bb1b280141c87f6195'
gem 'gabba'
gem 'rollbar'

gem 'unicorn'
gem 'rack-rewrite'

gem 'tlsmail'
gem 'roadie'

# gem 'test-unit'

# Use unicorn as the web server
# gem 'unicorn'

# To use debugger
# gem 'ruby-debug19'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end

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
end

group :development, :test do
  gem 'cucumber-rails', require: false
  gem 'rspec-activemodel-mocks'
  gem 'rspec-collection_matchers'
  gem 'rspec-its'
  gem 'rspec-rails', '~> 2.14'
  gem 'mocha'
  gem 'capybara'
  gem 'poltergeist'
  gem 'database_cleaner'
  gem 'launchy'    # So you can do Then show me the page
  gem "factory_girl_rails", "~> 1.2.0"
  gem 'vcr'
  gem 'fakeweb'
  gem 'pry'
  gem 'debugger'
end
