class DatasetCategory < ActiveRecord::Base
  has_many :dataset_descriptions, :foreign_key => "category_id", :dependent => :nullify
  
  translates :title, :description
  locale_accessor I18N_LOCALES
  
  validates_presence_of_i18n :title, :locales => [I18n.locale]
  
  def to_s
    title
  end
  
  def title
    title = attributes[:title]
    title = title.blank? ? translations.find(:first).title : title
    title.blank? ? '(n/a)' : title
  end
  
  def self.find_or_create_by_title(title)
    cat = find :first, :include => :translations, :conditions => {"dataset_category_translations.title" => title}
    if cat
      return cat
    else
      return self.create(:title => title)
    end
  end
end
