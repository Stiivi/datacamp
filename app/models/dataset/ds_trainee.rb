# -*- encoding : utf-8 -*-
class Dataset::DsTrainee < Dataset::DatasetRecord
  set_table_name "ds_trainees"
  
  has_many :rel_advokat_trainee, :class_name => "Dataset::RelAdvokatTrainee"
  has_many :ds_advokats, :class_name => "Dataset::DsAdvokat", :through => :advokat_trainee
end
