source 'http://rubygems.org'

gem 'rails', '3.0.9'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2', '~> 0.2.7'

gem 'haml-rails'
gem "RedCloth", :require => "redcloth"
gem "sequel"

gem 'globalize3'
gem 'paperclip'
gem 'recaptcha', :require => "recaptcha/rails"
gem 'spawn'
gem 'validation_reflection'
gem 'will_paginate', '3.0.pre2'
#gem 'restful-authentication', :git => 'git://github.com/Satish/restful-authentication.git', :branch => 'rails3'
gem 'delayed_job'
gem 'nokogiri'
gem 'riddle'
gem 'typhoeus'
gem 'delayed_job_admin'
gem 'whenever', :require => false
gem "exception_notification", :git => "git://github.com/rails/exception_notification", :require => 'exception_notifier'
gem 'newrelic_rpm'
gem 'thinking-sphinx', '>= 2.0.2', :require => 'thinking_sphinx'

gem 'test-unit'

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
  gem 'pry'
	gem "rails-erd"
	gem 'jquery-rails'
	gem 'awesome_print'
	gem 'rails_best_practices'
	# Deploy with Capistrano multistage
	gem 'capistrano'
	gem 'capistrano-ext'
end

group :development, :test do
	gem 'cucumber-rails'
	gem 'rspec-rails'
	gem 'mocha'
	gem 'capybara'
	gem 'database_cleaner'
	gem 'spork', '>= 0.9.0.rc2'
	gem 'launchy'    # So you can do Then show me the page
	gem "factory_girl_rails", "~> 1.2.0"
	gem 'vcr'

  gem 'guard-rspec'
  gem 'guard-livereload'
  gem 'guard-cucumber'
  gem 'guard-spork'
end
