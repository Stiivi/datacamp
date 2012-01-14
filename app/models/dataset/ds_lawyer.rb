# -*- encoding : utf-8 -*-
class Dataset::DsLawyer < Dataset::DatasetRecord
  set_table_name "ds_lawyers"
  
  has_many :rel_lawyers_associates, :class_name => "Dataset::RelLawyerAssociate"
  has_many :ds_associates, :class_name => "Dataset::DsAssociate", :through => :rel_lawyers_associates
  
  accepts_nested_attributes_for :ds_associates
  
  validates_uniqueness_of :url
end
