require 'rubygems'
require 'spork'

Spork.prefork do
  require 'cucumber/rails'

  # Capybara defaults to XPath selectors rather than Webrat's default of CSS3. In
  # order to ease the transition to Capybara we set the default here. If you'd
  # prefer to use XPath just remove this line and adjust any selectors in your
  # steps to use the XPath syntax.
  Capybara.default_selector = :css
  
  # This silences the annoying 'rack-1.2.3/lib/rack/utils.rb:16: warning: regexp match /.../n against to UTF-8 string'. If they fix it then the next line can be removed.
  $VERBOSE = nil
end

Spork.each_run do
  ActionController::Base.allow_rescue = false
  
  Cucumber::Rails::World.use_transactional_fixtures = true
  if defined?(ActiveRecord::Base)
    begin
      require 'database_cleaner'
      DatabaseCleaner.strategy = :truncation, {:except => %w[widgets]}
    rescue LoadError => ignore_if_database_cleaner_not_present
    end
  end
end


# By default, any exception happening in your Rails application will bubble up
# to Cucumber so that your scenario will fail. This is a different from how 
# your application behaves in the production environment, where an error page will 
# be rendered instead.
#
# Sometimes we want to override this default behaviour and allow Rails to rescue
# exceptions and display an error page (just like when the app is running in production).
# Typical scenarios where you want to do this is when you test your error pages.
# There are two ways to allow Rails to rescue exceptions:
#
# 1) Tag your scenario (or feature) with @allow-rescue
#
# 2) Set the value below to true. Beware that doing this globally is not
# recommended as it will mask a lot of errors for you!
#


# Remove/comment out the lines below if your app doesn't have a database.
# For some databases (like MongoDB and CouchDB) you may need to use :truncation instead.
# begin
#   DatabaseCleaner.strategy = :transaction
# rescue NameError
#   raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
# end

# You may also want to configure DatabaseCleaner to use different strategies for certain features and scenarios.
# See the DatabaseCleaner documentation for details. Example:
#
# Before('@no-txn,@selenium,@culerity,@celerity,@javascript') do
#   DatabaseCleaner.strategy = :truncation, {:except => %w[widgets]}
# end
#
# Before('~@no-txn', '~@selenium', '~@culerity', '~@celerity', '~@javascript') do
#   DatabaseCleaner.strategy = :transaction
# end
#


