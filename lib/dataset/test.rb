# -*- encoding : utf-8 -*-
class Dataset::Test
  
  @@test_path = File.join(Rails.root, "dataset_tests")
  cattr_reader :test_path
  attr_reader :log
  attr_accessor :title
  
  attr_reader :dataset_description
  
  ##############################################################################
  ## Factory methods
  
  def self.find_tests
    Dir.new(@@test_path).entries - [".", "..", ".svn"]
  end
  
  def self.find_test test_name
    require File.join(@@test_path, test_name+".rb")
    
    class_name = test_name.split('.')[0].camelize.constantize
    instance = class_name.new
    instance.title = test_name
    instance
  end

  ##############################################################################
  ## Instance methods

  def initialize
    @log = Dataset::Test::Log.new(self)
    
    setup
  end
end
