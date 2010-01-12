class SearchResult < ActiveRecord::Base
  set_table_name :search_results
    
  belongs_to :query, :class_name => "SearchQuery", :foreign_key => "search_query_id"
  belongs_to :record, :polymorphic => true, :foreign_key => "record_id", :primary_key => "_record_id", :foreign_type => "table_name", :extend => ( Module.new do
    def association_class
      begin
        return Dataset::Base.new(@owner.table_name).dataset_record_class
      rescue Exception => e
        return nil
      end
    end
  end)
  
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
