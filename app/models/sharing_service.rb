# -*- encoding : utf-8 -*-
require "cgi"

class SharingService < ActiveRecord::Base
  
  def gen_url options
    new_url = url
    options.each do |key, value|
      puts key.to_yaml
      puts value.to_yaml
      new_url.sub!("{%s}"%key.to_s, value)
    end
    new_url
  end
  
end
