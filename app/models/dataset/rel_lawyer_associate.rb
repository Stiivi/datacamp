# -*- encoding : utf-8 -*-
class Dataset::RelLawyerAssociate < Dataset::DatasetRecord
  set_table_name "rel_lawyers_associates"
  
  belongs_to :ds_lawyer, :class_name => "Dataset::DsLawer"
  belongs_to :ds_associate, :class_name => "Dataset::DsAssociate"
end
