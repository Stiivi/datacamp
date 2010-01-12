class ColumnDescription
attr_reader :name, :type, :extra, :is_null
def initialize(options)
	@name = options[:name]
	@type = options[:type]
	@extra = options[:extra]
	if options[:is_null] == 'YES' or options[:is_null] == true
		@is_null = true
	else
		@is_null = false
	end
	@extra = options[:extra]
end
end