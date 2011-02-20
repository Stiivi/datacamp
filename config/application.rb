# -*- encoding : utf-8 -*-
require File.expand_path('../boot', __FILE__)

require File.expand_path('../configuration', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

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

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    
    config.time_zone = 'UTC'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    
    config.i18n.load_path += Dir[File.join(Rails.root, 'config', 'locales', '**', '*.{rb,yml}')]
    config.i18n.default_locale = :sk

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    
    config.action_mailer.delivery_method = :sendmail
    
    config.after_initialize do
      DatasetDescription.all.each do |dataset_description|
        dataset_description.dataset.dataset_record_class.define_index do
          indexes :_record_id
          dataset_description.visible_field_descriptions(:search).each do |field|
            if field.data_type == 'string'
              indexes field.identifier.to_sym, :sortable => true if field.identifier.present?
            else
              has field.identifier.to_sym if field.identifier.present?
            end
            has "#{field.identifier} IS NOT NULL", :type => :integer, :as => "#{field.identifier}_not_nil" if field.identifier.present?
            has "#{field.identifier} IS NULL", :type => :integer, :as => "#{field.identifier}_nil" if field.identifier.present?
          end
        end
      end
    end
    
  end
end