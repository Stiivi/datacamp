require 'digest/sha1'

class ApiKey < ActiveRecord::Base
  
  belongs_to :user
  
  def to_s
    key
  end
  
  def init_random_key
    
    string_to_be_encoded = user.login + \
                           Time.now.to_s + \
                           rand(1000).to_s
                           
    self.key = Digest::SHA1.hexdigest(string_to_be_encoded)
    
  end
  
end