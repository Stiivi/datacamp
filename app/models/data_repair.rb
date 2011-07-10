class DataRepair < ActiveRecord::Base
  
  serialize :record_ids
  
  def run_data_repair
    regis_model = DatasetDescription.find_by_identifier(regis_table_name).dataset.dataset_record_class
    target_model = DatasetDescription.find_by_identifier(target_table_name).dataset.dataset_record_class
    begin
      target_model.connection.execute("
        UPDATE #{target_model.table_name} 
        JOIN #{regis_model.table_name} ON #{regis_model.table_name}.#{regis_ico_column} = #{target_model.table_name}.#{target_ico_column} 
        SET #{target_model.table_name}.#{target_company_name_column} = #{regis_model.table_name}.#{regis_name_column},
        #{target_model.table_name}.#{target_company_address_column} = #{regis_model.table_name}.#{regis_address_column}
        WHERE #{target_model.table_name}.#{target_company_name_column} IS NULL OR #{target_model.table_name}.#{target_company_address_column} IS NULL")
      update_attribute(:repaired_records, records_to_repair)
      update_attribute(:status, 'done')
    rescue
      update_attribute(:status, 'error')
    end
  end
end
