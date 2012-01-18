# -*- encoding : utf-8 -*-
class Kernel::DsLawyerPartnership < Dataset::DatasetRecord
  set_table_name 'ds_lawyer_partnerships'
  validates_uniqueness_of :sak_id
end
