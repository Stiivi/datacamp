# -*- encoding : utf-8 -*-
class Kernel::DsLawyerPartnership < Dataset::DatasetRecord
  set_table_name 'ds_lawyer_partnerships'
  
  has_many :dc_relations_left, class_name: 'Dataset::DcRelation', as: :relatable_left
  has_many :ds_lawyers, through: :dc_relations_left, source: :relatable_right, source_type: 'Kernel::DsLawyer'
  accepts_nested_attributes_for :ds_lawyers
  
  has_many :dc_relations_right, class_name: 'Dataset::DcRelation', as: :relatable_right
  has_many :ds_lawyer_associates, through: :dc_relations_right, source: :relatable_left, source_type: 'Kernel::DsLawyerAssociate'
  accepts_nested_attributes_for :ds_lawyer_associates
  
  
  validates_uniqueness_of :sak_id
end
