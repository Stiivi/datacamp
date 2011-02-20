# -*- encoding : utf-8 -*-
require "shellwords"
require 'logger'

module SearchEngineDelegate
def search_failed severity, message
	# do nothing
end
end

class SearchEngine
include SearchEngineDelegate
attr_reader :delegate
include Shellwords
########################################################################
# All-purpose initializer (More ways to initialize search might be added)
########################################################################

def initialize 
	@delegate = self
	@connection = Search.connection
end

def delegate=(anObject)
	if anObject
		@delegate = anObject
	else
		@delegate = self
	end
end
########################################################################
# Factory methods

# FIXME: factory methods should be defined as class methods [not instance]
# thus def self.create_global_search_with_string, etc ...
# And than it will be called just with SearchEngine.create_global_search_with_string, etc ...

def create_global_search_with_string(string)
	return create_search_with_string(string, :global, nil)
end

def create_search_with_string(query_string, scope, object_name)
	search = Search.new
	begin
		query = SearchQuery.query_with_string(query_string, :scope=>scope.to_s, :object=>object_name)
		search.query = query
		search.query_string = query_string
		search.search_type = "text"
		search.save
	rescue ArgumentError => exception
		# FIXME: provide more details
		@delegate.search_failed :warning, "search query syntax error: #{exception.message}"
		return nil
	end


	#FIXME: set user ID, set session ID
	
	return search
end  

def create_dataset_search_with_predicates(predicates, dataset)
  raise "Predicates shouldn't be nil" if predicates.nil?
  
	search = Search.new
	query = SearchQuery.query_with_predicates(predicates, :scope=>"dataset", :object=>dataset)
	search.query = query
	search.search_type = "predicates"
	search.save
	
	return search
end

########################################################################
# Heart of searching - method to find all results

def perform_search(search, options = {})
	# Note: currenlty we have only search query stored in the query object of
	#       search object
	
	# Do not perform search, if there already are results for this query
	# Rails.logger.info("DEBUG Search string '#{search.query_string}'")
	
	# FIXME: remove comment (IMPORTANT!!!)
	# if @search.result_count > 0
	#  return 
	# end
	
	query = search.query
	scope = query.scope.to_sym
	
	# Option to temporarily change scope.
	if options[:dataset]
	 scope = :dataset
	end
	
	if not scope or scope == :global
		# Rails.logger.info "DEBUG global search"
		# Find datasets where search will be performed
		datasets = query.searched_datasets
	
		# FIXME: this sanity check should be somewhere else
		datasets = datasets.select { |dd|dd.dataset.table_exists? }
		datasets.each do |dataset|
			perform_dataset_search(dataset, query, options)
		end
	elsif scope == :dataset
		# Rails.logger.info "DEBUG dataset search: #{query.object}"
		dataset_identifier = options[:dataset] || query.object
		dataset = DatasetDescription.find_by_identifier(dataset_identifier)
		perform_dataset_search(dataset, query, options)
	else
		raise "Unknown search query scope #{scope}"
	end
end

########################################################################
# Protected methods

protected

def sql_condition_for_dataset_query(dataset, query)
	all_fields = dataset.field_descriptions
	all_field_names = all_fields.collect { |field| field.identifier }

	# FIXME: include field descriptions
	# FIXME: use aliases
	# FIXME: refactor this. currently old code is reused

	searched_field_names = all_fields.collect { |field| field.identifier }
	field_predicates = query.predicates.select { |predicate| predicate.scope == "field" }
	include_predicates = field_predicates.select { |p| p.operator == "contains" }
	include_fields = include_predicates.collect { |p| p.argument }

	exclude_predicates = field_predicates.select { |p| p.operator == "does_not_contain" }
	exclude_fields = include_predicates.collect { |p| p.argument }

	if not include_fields.nil? and not include_fields.empty?
		searched_field_names = searched_field_names.select { | field |
			array = include_fields.select { | inc |
				field.include?(inc)
			}
			not array.empty?
		}
	end
	
	if not exclude_fields.nil? and not exclude_fields.empty?
		searched_field_names = searched_field_names.select { | field |
			array = exclude_fields.select { | inc |
				field.include?(inc)
			}
			array.empty?
		}
	end

	#real_fields = searched_fields.select{|field| (not field.is_derived?) and dataset.dataset.has_column?(field.identifier)}
	#derived_fields = fields.select{|field| field.is_derived?}


	# Now we have all fields where we would like to perform search in
	# FIXME: check for datatypes and ignore numbers for text
	# FIXME: deal with derived columns
	
	# include only searchable fields

	# Rails.logger.info "DEBUG searched_fields: #{searched_fields.join(',')}"
	# Rails.logger.info "DEBUG all_fields: #{all_fields.join(',')}	"

	conditions = []

	# Rails.logger.info "DEBUG prepare conditions"
	record_predicates = query.predicates.select { |p| p.scope == "record" }
	
	record_predicates.each { |predicate|
		# Rails.logger.info "DEBUG -- f:#{predicate.field} a:#{predicate.argument}"
		if predicate.search_field and all_field_names.include?(predicate.search_field)
			# IF field is specified, use that field
			field = dataset.field_with_identifier(predicate.search_field)
			
			condition = sql_condition_for_field(predicate, dataset, field)
			# Rails.logger.info "DEBUG condition: #{condition}"
			if condition
				conditions << condition
			end
		else
			# IF field is not specified, search in all fields
			sub_conditions = Array.new

			searched_field_names.each { |field_name| 
				field = dataset.field_with_identifier(field_name)
				condition = sql_condition_for_field(predicate, dataset, field)
				# Rails.logger.info "DEBUG condition: #{condition}"
				if condition
					sub_conditions << condition
				end
			}

			conditions << sub_conditions.join(" OR ")
		end
	}

	if conditions.empty?
		# Rails.logger.info "DEBUG no conditions"
		return nil
	else
		sql_condition = conditions.collect{|cond|"(#{cond})"}.join(" AND ")
		# Rails.logger.info "DEBUG condition: #{sql_condition}"
		return sql_condition		
	end
end

def sql_condition_for_field(predicate, dataset, field)
	# Rails.logger.info "DEBUG condition for field f:#{field.identifier} #{field.is_derived}"

	if field.is_derived
		# Rails.logger.info "DEBUG derived f:#{field.identifier} v:#{field.derived_value}"
		operand = field.derived_value
	else
		if dataset.dataset.has_column?(field.identifier)
			# Rails.logger.info "DEBUG raw field f:#{field.identifier}"
			operand = field.identifier
		else
			# Rails.logger.info "DEBUG unknown field f:#{field.identifier}"
			operand = nil
		end
	end

	if operand
		# Filter using data types
		types = operand_types(operand)
		field_type = field.data_type

		# Do not search in numeric fields, if operand is not a number
		if (field_type == :integer or field_type == :numeric) and (not types.include?(:numeric))
			return nil
		else		
			condition = predicate.sql_condition_for_operand(operand)
		end
	end

	# Rails.logger.info "DEBUG operand '#{operand}'"
	# Rails.logger.info "DEBUG condition '#{condition}'"

	return condition
end

def operand_types(operand)
	types = Array.new
	if operand =~ /((\b[0-9]+)?\.)?\b[0-9]+([eE][-+]?[0-9]+)?\b/
		types << :numeric
	end
	if operand =~ /[-+]?\b\d+\b/
		types << :integer
	end
	return types
end

########################################################################
# Select into method
#

def perform_dataset_search(dataset, query, options)

    if options
        dataset_limit = options[:dataset_limit]
    end

	search_expression = sql_condition_for_dataset_query(dataset, query)
	# Rails.logger.info "DEBUG search in #{dataset}: #{search_expression}"
	if not search_expression
		return
	end
	
	# FIXME: use DatastoreManager
	dataset_schema = @connection.current_database
	target_table = "#{dataset_schema}.search_results"

    # FIXME: make this database independent (this is MySQL)
    if dataset_limit
        limit_condition = "LIMIT #{dataset_limit}"
    end

  	# FIXME: use datastore 
    sql_query = "INSERT INTO #{target_table} (search_query_id, table_name, record_id)
                 SELECT '#{query.id}', '#{dataset.identifier}', _record_id
                 FROM #{dataset.dataset.table_name}
                 WHERE #{search_expression} #{limit_condition}"
	
	begin
		# Now fill results with stuff from table ...
        
        # FIXME: use datastore connection
    	DatasetRecord.connection.execute(sql_query)

	rescue Exception => e
		# FIXME: create list of errors, pass an message
		Rails.logger.error e.message
		Rails.logger.error e.backtrace.join("\n")
		@delegate.search_failed :warning, "results from dataset '#{dataset.identifier}' were excluded"
	end
end

end
