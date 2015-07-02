module Datacamp
  class Railtie < ::Rails::Railtie
    console do
      require 'hirb'
      Hirb.enable
    end
  end
end
