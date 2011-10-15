# -*- encoding : utf-8 -*-
class Dataset::DsAdvokat < Dataset::DatasetRecord
  set_table_name "ds_advokats"
  
  has_many :rel_advokat_trainee, :class_name => "Dataset::RelAdvokatTrainee"
  has_many :ds_trainees, :class_name => "Dataset::DsTrainee", :through => :rel_advokat_trainee
  
  accepts_nested_attributes_for :ds_trainees
  
  validates_uniqueness_of :url
end
