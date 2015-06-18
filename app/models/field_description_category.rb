class FieldDescriptionCategory < ActiveRecord::Base
  has_many :category_assignments
  has_many :dataset_descriptions, through: :category_assignments

  has_many :field_descriptions
  translates :title
  locale_accessor I18N_LOCALES

  default_scope order(:position)
end
