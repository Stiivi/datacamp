# -*- encoding : utf-8 -*-
class ApplicationLogger
  
  attr_reader :messages
  
  def initialize
    @messages = []
  end
  
  def info message
    log :success, message
  end
  
  def warning message
    log :notice, message
  end
  
  def error message
    log :error, message
  end
  
  def log type, message
  	log_message = LogMessage.new
  	log_message.type = type
  	log_message.message = message
  	log_message.time = Time.now
    @messages << log_message
  end
end
