# -*- encoding : utf-8 -*-
class Dataset::RelLawyerPartnership < Dataset::DatasetRecord
  set_table_name "rel_lawyers_partnerships"
  
  belongs_to :ds_lawyer, :class_name => "Dataset::DsLawyer"
  belongs_to :ds_lawyer_partnership, :class_name => "Dataset::DsLawyerPartnership"
end
