require "test_helper"

class CsvFileTest < ActiveSupport::TestCase
  def setup
    @proper_file_path = File.join(RAILS_ROOT, "test", "test_files", "file.csv")
    @wrong_file_path  = File.join(RAILS_ROOT, "test", "test_files", "wrong_file.csv")
  end
end