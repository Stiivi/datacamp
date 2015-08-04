# -*- encoding : utf-8 -*-
class DatasetCategory < ActiveRecord::Base
  has_many :dataset_descriptions, :foreign_key => "category_id", :dependent => :nullify, :order => :position
  
  default_scope includes(:translations)
  
  translates :title, :description
  locale_accessor I18N_LOCALES
  
  validates_presence_of_i18n :title, :locales => [I18n.locale]

  def filtered_descriptions(only_good_quality)
    if only_good_quality
      dataset_descriptions.reject {|d| d.bad_quality }
    else
      dataset_descriptions
    end
  end
  
  def to_s
    title
  end
  
  def title
    title = read_attribute(:title)
    title = translations.first.title if title.blank? && translations.first.present?
    title.blank? ? '(n/a)' : title
  end
  
  def self.find_or_create_by_title(title)
    cat = where("dataset_category_translations.title" => title).includes(:translations).first
    if cat
      return cat
    else
      return self.create(:title => title)
    end
  end
end
