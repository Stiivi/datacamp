# -*- encoding : utf-8 -*-
require File.expand_path('../boot', __FILE__)

require File.expand_path('../configuration', __FILE__)

require 'rails/all'

require 'csv'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require *Rails.groups(:assets => %w(development test))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Datacamp
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    config.autoload_paths += %W( #{Rails.root}/app/form_builders )
    config.autoload_paths += %W( #{Rails.root}/lib )

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    config.assets.enabled = true
    config.assets.version = '1.0'

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    config.time_zone = 'Bratislava'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.i18n.enforce_available_locales = false # silence warning "[deprecated] I18n.enforce_available_locales will default to true in the future. If you really want to skip validation of your locale you can set I18n.enforce_available_locales = false to avoid this message."
    config.i18n.load_path = Dir[File.join(Rails.root, 'config', 'locales', '**', '*.{rb,yml}')]
    config.i18n.default_locale = :sk
    config.i18n.locale = config.i18n.default_locale # weird bug, but this fix the problem in test and production environment http://stackoverflow.com/questions/8478597/rails-3-set-i18n-locale-is-not-working

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    config.action_mailer.delivery_method = :sendmail

    config.action_mailer.default_url_options = { host: 'datanest.fair-play.sk' }

    config.after_initialize do
      SphinxDatasetIndex.define_indices_for_all_datasets
    end

    config.admin_emails = ''

    config.middleware.insert_before(Rack::Lock, Rack::Rewrite) do
      r301 %r{.*}, "http://#{Datacamp::Config.get('canonical_url')}$&", if: Proc.new {|rack_env|
        Datacamp::Config.get('canonical_url').present? && rack_env['SERVER_NAME'] != Datacamp::Config.get('canonical_url')
      }
    end

  end
end
