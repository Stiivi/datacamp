# -*- encoding : utf-8 -*-
class Search < ActiveRecord::Base

  belongs_to :query, :class_name => "SearchQuery", :foreign_key => "search_query_id"
  belongs_to :session
  
  attr_accessor :search_query, :categories
  
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
