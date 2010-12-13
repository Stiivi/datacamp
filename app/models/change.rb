# -*- encoding : utf-8 -*-
class Change < ActiveRecord::Base
  belongs_to :dataset_description
  belongs_to :user
end
