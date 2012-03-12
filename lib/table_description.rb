# -*- encoding : utf-8 -*-
class TableDescription
attr_reader :column_descriptions, :column_names
def initialize(connection, tableName)
	columns = connection.select_all("SHOW FIELDS FROM #{tableName}")
	@column_names = columns.collect { |c| c["Field"] }
	@column_descriptions = Hash.new
	columns.each { |c|
		desc = ColumnDescription.new({ :name => c["Field"],
		                               :type => c["Type"],
									   :is_null => c["Null"],
									   :default => c["Default"],
									   :extra => c["Extra"]})
		@column_descriptions[desc.name] = desc
	}
end

def description_for_column(column)
	@column_descriptions[column]
end
def type_of_column(column)
	@column_descriptions[column].type
end
def field_type_of_column(column)
	type = @column_descriptions[column].type.gsub(/\(.*/,'')
	type = case type
			when 'varchar' then 'string'
			when 'char' then 'string'
			when 'int' then 'integer'
			else type
			end
	type
end
end
