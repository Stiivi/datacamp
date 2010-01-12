class CsvFile
  attr_reader :path, :collection, :errors
  
  def initialize path, colsep = ';', header_lines = 0
    @errors = []
    
    @path = path
    @colsep = colsep
    @header_lines = header_lines
  end
  
  def open
    @file = File.readable?(@path) ? FasterCSV.open(@path, "r", :col_sep => @colsep) : false
    @file.rewind
  end
  
  def skip_header_lines
    if @header_lines
      @header_lines.times { @file.shift }
    end
  end
  
  def load_lines count = 1, skip_header = false
    @file.rewind
    if skip_header
      skip_header_lines
    end
    @lines = []
    count.times do
      row = @file.shift
      @lines << row if row && !row.empty?
    end
    @lines
  end
  
  def each skip_header = false
    @file.rewind
    if skip_header
      skip_header_lines
    end
    while row = @file.shift
      yield row
    end
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
  
  protected
  
  def check_collection
    raise("Collection is empty: Please call fetch before accessing the collection") unless @lines
  end
end