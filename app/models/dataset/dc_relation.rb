# -*- encoding : utf-8 -*-
class Dataset::DcRelation < Dataset::DatasetRecord
  self.table_name  = 'dc_relations'
  
  belongs_to :relatable_left, polymorphic: true
  belongs_to :relatable_right, polymorphic: true
end
