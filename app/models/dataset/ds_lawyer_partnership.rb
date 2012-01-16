# -*- encoding : utf-8 -*-
class Dataset::DsLawyerPartnership < Dataset::DatasetRecord
  set_table_name "ds_lawyer_partnerships"
  
  has_many :rel_lawyer_partnership, :class_name => "Dataset::RelLawyerPartnership"
  has_many :ds_lawyers, :class_name => "Dataset::DsLawyer", :through => :rel_lawyer_partnership
  
  has_many :rel_associate_partnership, :class_name => "Dataset::RelAssociatePartnership"
  has_many :ds_associates, :class_name => "Dataset::DsAssociate", :through => :rel_associate_partnership
  
  validates_uniqueness_of :sak_id
end
