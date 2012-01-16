# -*- encoding : utf-8 -*-
class Dataset::RelAssociatePartnership < Dataset::DatasetRecord
  set_table_name "rel_associates_partnerships"
  
  belongs_to :ds_lawyer_partnership, :class_name => "Dataset::DsLawerPartnership"
  belongs_to :ds_associate, :class_name => "Dataset::DsAssociate"
end
