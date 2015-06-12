# -*- encoding : utf-8 -*-
class Favorite < ActiveRecord::Base

  belongs_to :user
  belongs_to :dataset_description
  
  belongs_to :record, polymorphic: true

  validates :dataset_description, :user, presence: true

  def self.by_record(record)
    where(record_type: record.class.to_s, record_id: record.id)
  end

  def self.by_dataset_description(dataset_description)
    where(dataset_description_id: dataset_description.id)
  end

  def excerpt
    matches = []

    dataset_description.visible_field_descriptions(:search).each do |description|
      if record && record[description.identifier.to_sym]
        matches << [description.title, record.get_html_value(description)]
      end
    end

    matches.collect { |attribute, value| "<em>#{html_escape(attribute)}:</em> #{html_escape(value)}" }.join("<br />").html_safe
  end
end
