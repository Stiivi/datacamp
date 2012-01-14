# -*- encoding : utf-8 -*-
class Dataset::DsAssociate < Dataset::DatasetRecord
  set_table_name "ds_associates"
  
  has_many :rel_lawyer_associate, :class_name => "Dataset::RelLawyerAssociate"
  has_many :ds_lawyers, :class_name => "Dataset::DsLawyer", :through => :rel_lawyer_associate
end
