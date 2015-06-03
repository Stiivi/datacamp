# -*- encoding : utf-8 -*-
module Datacamp
  class Config
    include Singleton

    def initialize
      path = File.join(Rails.root, "config", "datacamp_config.yml")
      if(File.exist?(path))
        @config = YAML.load(ERB.new(File.read(path)).result)
        # TODO: backward compatibility - remove this check after updating config file in production
        if @config.key?(Rails.env)
          @config = @config[Rails.env]
        end
      else
        Rails.logger.warn("Can't open config file at #{path}")
      end
    end

    def get(variable, default = nil)
      @config[variable.to_s] || default
    end

    def self.get(*args)
      self.instance.get(*args)
    end
  end
end
