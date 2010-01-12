class Dataset::Test::LogMessage
  attr_reader :type, :message
  
  def initialize type, message
    @type = type
    @message = message
  end
end