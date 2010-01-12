class Change < ActiveRecord::Base
  belongs_to :dataset_description
  belongs_to :user
end