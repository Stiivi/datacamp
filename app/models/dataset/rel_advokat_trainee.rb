# -*- encoding : utf-8 -*-
class Dataset::RelAdvokatTrainee < Dataset::DatasetRecord
  set_table_name "rel_advokats_trainees"
  
  belongs_to :ds_advokats, :class_name => "Dataset::DsAdvokat"
  belongs_to :ds_trainee, :class_name => "Dataset::DsTrainee"
  
  validates_uniqueness_of :url
end
