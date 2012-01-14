# -*- encoding : utf-8 -*-
class Dataset::RelLawyerAssociate < Dataset::DatasetRecord
  set_table_name "rel_lawyers_associates"
  
  belongs_to :ds_lawyers, :class_name => "Dataset::DsLawers"
  belongs_to :ds_associates, :class_name => "Dataset::DsAssociates"
end
