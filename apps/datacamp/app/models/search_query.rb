require 'shellwords'
require 'yaml'

class SearchQuery < ActiveRecord::Base

# Active Record stuff ...
set_table_name :search_queries
has_many :searches
has_many :search_predicates
has_many :predicates, :class_name => "SearchPredicate"

has_many :results, :class_name => "SearchResult", :foreign_key => "search_query_id"
after_initialize :after_initalize

attr_reader :include_words, :exclude_words, :include_datasets, :exclude_datasets
attr_reader :include_categories, :exclude_categories, :include_fields, :exclude_fields
attr_reader :include_match_predicate, :exclude_match_predicate

####################################################################################
# Factory method for new query based on string (string need to be broken down into
# predicates first)
def self.query_with_string(string, options = {})
	# tokenize
	tokens = self.parse_string(string)
	query_yaml = tokens.to_yaml
	
	scope = options[:scope]
	object = options[:object]
	
	# query = SearchQuery.find(:first, :conditions =>
	#									[ "query_yaml = ? AND scope = ? AND object = ?",
	#									query_yaml, scope, object])
	query = self.new
	query.query_yaml = query_yaml
	query.scope = scope
	query.object = object
	query.create_predicates_from_tokens(tokens)
	query.save

	return query
end

####################################################################################
# Factory method with predicates as hash
def self.query_with_predicates(predicates, *args)
	options = args.extract_options!
	
	query = self.new
	# FIXME: use ids of predicates
	query.query_yaml = predicates.to_yaml
	query.scope = options[:scope]
	query.object = options[:object]
	query.predicates = predicates
	query.save
	
	return query
end

####################################################################################
# Create predicates from tokens (from search query basically)
def create_predicates_from_tokens(tokens)
	# puts "==> predicate from tokens #{tokens}"

	tokens.each { |token|
		# puts "--- token '#{token}'"

		exclude = false
		if token[0, 1] == "-"
			exclude = true
			token = token.sub(/^-/, "")
		end
	
		if token =~ /^\w*:.*/ 
			split = token.match(/^(\w+):(.*)/)
			keyword = split[1]
			token_argument = split[2]
	
			# FIXME: use internationalized keywords
			case keyword
			when 'dataset'
				scope = 'dataset'
				argument = token_argument
				field = "name"
			when 'category'
				scope = 'category'
				argument = token_argument
				field = "name"
			when 'field'
				scope = 'field'
				argument = token_argument
				field = "name"
			else
				# FIXME: handle this more gracefuly
				# undefined! raise exception
				raise "unknown keyword"				
			end

			predicate = SearchPredicate.new
			predicate.scope = scope
			predicate.field = field
			predicate.argument = argument
			if not exclude
				predicate.operator = "contains"
			else
				predicate.operator = "does_not_contain"
			end
		else
			predicate = SearchPredicate.new
			predicate.scope = "record"
			predicate.field = nil

			argument = nil
			if token =~ /^\*.*[^\*]$/
				argument = token.gsub(/^\*/,"")
				if not exclude
					operator = "ends_with"
				else
					operator = "does_not_end_with"
				end
			elsif token =~ /^[^\*].*\*$/
				argument = token.gsub(/\*$/,"")
				if not exclude
					operator = "begins_with"
				else
					operator = "does_not_begin_with"
				end
			elsif token =~ /^\*.*\*$/
				argument = token.gsub(/(^\*)|(\*$)/, "")
			else
				argument = token	
			end

			if not operator
				if not exclude
					operator = "contains"
				else
					operator = "does_not_contain"
				end
			end
			predicate.argument = argument
			predicate.operator = operator
		
		end
		predicate.save
		predicates << predicate
	}	
end

####################################################################################
# Create predicates from hash
def create_predicates_from_hash(hash)
  raise hash.to_yaml
end

def self.parse_string(query_string)
	return [] unless query_string
	tokens = Shellwords.shellwords(query_string)
	return tokens
end

def searched_datasets
	datasets = DatasetDescription.find(:all)
	
	Rails.logger.info "search: find datasets"

	# FIXME: use aliases
	# FIXME: remove accents/diacritics
	dataset_predicates = predicates.select { |predicate| predicate.scope == "dataset" }
	include_predicates = dataset_predicates.select { |p| p.operator == "contains" }
	include_datasets = include_predicates.collect { |p| p.argument }

	Rails.logger.info "search: include datasets: #{include_datasets.join(',')}"


	exclude_predicates = dataset_predicates.select { |p| p.operator == "does_not_contain" }
	exclude_datasets = include_predicates.collect { |p| p.argument }

	Rails.logger.info "search: exclude datasets: #{include_datasets.join(',')}"

	
	if not include_datasets.nil? and not include_datasets.empty?
		datasets = datasets.select { | dataset |
			array = include_datasets.select { | inc |
				dataset.identifier.include?(inc) or dataset.title.downcase.include?(inc)
			}
			not array.empty?
		}
	end
	if not exclude_datasets.nil? and not exclude_datasets.empty?
		datasets = datasets.select { | dataset |
			array = exclude_datasets.select { | inc |
				dataset.identifier.include?(inc) or dataset.title.downcase.include?(inc)
			}
			array.empty?
		}
	end
	
	Rails.logger.info "search: final datasets: #{datasets.join(',')}"

	return datasets	
end

end
