# -*- encoding : utf-8 -*-
class Search < ActiveRecord::Base

  belongs_to :query, :class_name => "SearchQuery", :foreign_key => "search_query_id"
  belongs_to :session

  attr_accessor :search_query, :categories

  def self.build_from_query_string(query_string)
    search = new(query_string: query_string, search_type: :text)

    query = SearchQuery.query_with_string(query_string, scope: :global, object: nil)
    search.query = query

    search
  end

  def results
    query.results
  end

  def result_count
    query.results.count
  end

  def scope
    query.scope
  end
end
