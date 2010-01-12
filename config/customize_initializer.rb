# Set correct application schema

class Rails::Initializer
  def initialize_database
    if configuration.frameworks.include?(:active_record)
      ActiveRecord::Base.configurations = configuration.database_configuration
      ActiveRecord::Base.establish_connection(RAILS_ENV + "_app")
    end
  end
end