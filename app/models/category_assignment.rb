class CategoryAssignment < ActiveRecord::Base
  belongs_to :dataset_description
  belongs_to :field_description_category
end
