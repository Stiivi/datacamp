# -*- encoding : utf-8 -*-

class CsvFile
  
  def initialize(path, col_sep, encoding, batch_id, skip_first_line = false, has_header = true)
    @path, @col_sep, @encoding, @batch_id, @skip_first_line, @has_header = path, col_sep, encoding, batch_id, skip_first_line, has_header
  end
  
  def rewind_and_skip_first_line
    csv_file.rewind
    csv_file.readline if @skip_first_line
  end
  
  def rewind_and_skip_headers
    rewind_and_skip_first_line
    csv_file.readline if @has_header
  end
  
  def header
    rewind_and_skip_first_line
    parse_line
  end
  
  def sample
    rewind_and_skip_headers
    parse_line
  end
  
  def parse_line
    CSV.parse_line(csv_file.readline, col_sep: @col_sep)
  end
  
  def is_valid?
    CSV.parse(csv_file.read, col_sep: @col_sep)
  rescue Exception
    false
  end
  
  def parse_all_lines
    rewind_and_skip_headers
    while !csv_file.eof?
      yield parse_line
    end
  end
private
  def csv_file
    read_mode = @encoding ? "r:#{@encoding}" : "r"
    @file ||= File.open(@path, read_mode)
  end
end
