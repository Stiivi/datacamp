# -*- encoding : utf-8 -*-
class Favorite < ActiveRecord::Base
  belongs_to :user
  belongs_to :dataset_description
  
  belongs_to :record, :polymorphic => true, :foreign_key => "record_id", :foreign_type => "table_name", :extend => ( Module.new do
    def association_class
      begin
        return Dataset::Base.new(@owner.dataset_description).dataset_record_class
      rescue Exception => e
        return nil
      end
    end
  end)
  
  def excerpt
    matches = []

    dataset_description.visible_field_descriptions(:search).each do |description|
      if self.record[description.identifier.to_sym]
        matches << [description.title, record.get_html_value(description)]
      end
    end

    matches.collect { |attribute, value| "<em>#{attribute}:</em> #{value}" }.join("<br />")
  end
end
