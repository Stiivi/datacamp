# -*- encoding : utf-8 -*-
class SearchResult < ActiveRecord::Base

  belongs_to :query, :class_name => "SearchQuery", :foreign_key => "search_query_id"
  belongs_to :dataset_description, :foreign_key => "table_name", :primary_key => "identifier"
  belongs_to :record, :polymorphic => true, :foreign_key => "record_id", :primary_key => "_record_id", :foreign_type => "table_name"
  
  def description
    DatasetDescription.find_by_identifier(table_name)
  end
  
  def excerpt
    tokens = YAML.load(query.query_yaml)
    matches = []
    
    return unless record

    description.visible_field_descriptions(:search).each do |description|
      if record[description.identifier.to_sym]
        matches << [description.title, record.get_html_value(description)]
      end
    end

    matches.collect { |attribute, value| "<em>#{attribute}:</em> #{value}" }.join("<br />")
  end
end
