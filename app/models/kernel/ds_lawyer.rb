# -*- encoding : utf-8 -*-
class Kernel::DsLawyer < Dataset::DatasetRecord
  set_table_name 'ds_lawyers'
  
  has_many :dc_relations_right, class_name: 'Dataset::DcRelation', as: :relatable_right
  has_many :ds_lawyer_associates, through: :dc_relations_right, source: :relatable_left, source_type: 'Kernel::DsLawyerAssociate'
  accepts_nested_attributes_for :ds_lawyer_associates
  
  has_many :dc_updates, class_name: 'Dataset::DcUpdate', as: :updatable
  
  validates_uniqueness_of :sak_id
end
