# -*- encoding : utf-8 -*-
class Kernel::DsLawyerAssociate < Dataset::DatasetRecord
  set_table_name "ds_lawyer_associates"
  
  has_many :dc_relations_right, class_name: 'Dataset::DcRelation', as: :relatable_right
  has_many :ds_lawyers, through: :dc_relations_right, source: :relatable_left, source_type: 'Kernel::DsLawyer'
  
  
  has_many :dc_relations_right_morphed, class_name: 'Dataset::DcRelation', as: :relatable_right, conditions: {morphed: true}
  has_many :ds_lawyers_morphed, through: :dc_relations_right_morphed, source: :relatable_left, source_type: 'Kernel::DsLawyer'
  
  has_many :dc_relations_left, class_name: 'Dataset::DcRelation', as: :relatable_left
  has_many :ds_lawyer_partnerships, through: :dc_relations_left, source: :relatable_right, source_type: 'Kernel::DsLawyerPartnership'
end
