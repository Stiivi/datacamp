# -*- encoding : utf-8 -*-
require 'csv'

class CsvFile
  attr_reader :path, :collection, :errors
  attr_accessor :encoding, :header_lines
  
  def initialize path, colsep = ';', header_lines = 0
    @errors = []
    
    @path = path
    @colsep = colsep
    @header_lines = header_lines
  end
  
  def open
    read_mode = @encoding ? "r:#{@encoding}" : "r"
    @file = File.readable?(@path) ? CSV.new(File.open(@path, read_mode).read.encode("utf-8"), :col_sep => @colsep) : false
    self.rewind
  end
  
  def rewind(skip_header = true)
    @file.rewind
    skip_header_lines if skip_header
  end
  
  def skip_header_lines
    if @header_lines
      @header_lines.times { readline }
    end
  end
  
  def load_lines count = 1, skip_header = false
    self.rewind(skip_header)
    @lines = []
    count.times do
      break if @file.eof?
      row = readline
      @lines << row if row && !row.empty?
    end
    @lines
  end
  
  def each skip_header = false
    self.rewind(skip_header)
    while row = readline
      yield row
    end
  end
  
  def readline
    line = @file.readline
    if @encoding
      begin
        line = line.collect do |column|
          # Iconv.conv('utf-8', @encoding, column)
          column
        end
      rescue
      end
    end

    # raise line.to_yaml
    return line
  end
  
  def loaded?
    @file ? true : false
  end
  
  def same_count_of_columns?
    counts = @lines.map { |r| r.size }
    counts.min == counts.max ? true : false
  end
  
  def count_of_columns
    counts = @lines.map { |r| r.size }
    counts.max
  end
  
  def column_count
    count_of_columns
  end
  
  def method_missing name, *args
    @file.send(name, *args)
  end
  
  protected
  
  def check_collection
    raise("Collection is empty: Please call fetch before accessing the collection") unless @lines
  end
end
