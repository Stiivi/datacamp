namespace :clean do
  task staging_regis: :environment do
    Staging::StaRegisMain.find_by_sql("SELECT doc_id FROM sta_regis_main GROUP BY doc_id HAVING ( COUNT(doc_id) > 1 )").each do |item|
      duplicate_group = Staging::StaRegisMain.where(doc_id: item.doc_id)
      duplicate_group.pop
      duplicate_group.each do |duplicate_item|
        puts "destroying doc_id: #{item.doc_id}, id: #{duplicate_item.id}, ico: #{duplicate_item.ico}"
        duplicate_item.destroy
      end
    end
  end

  task production_regis: :environment do
    organisation_model = DatasetDescription.find_by_identifier('organisations').dataset_model
    organisation_model.find_by_sql("SELECT doc_id FROM ds_organisations GROUP BY doc_id HAVING ( COUNT(doc_id) > 1 )").each do |item|
      doc_id = item.doc_id
      organisation_model.where(doc_id: doc_id).each do |duplicate_item|
        puts "destroying doc_id: #{doc_id}, id: #{duplicate_item._record_id}, ico: #{duplicate_item.ico}"
        Staging::StaRegisMain.where(ico: duplicate_item.ico).update_all(etl_loaded_date: nil)
        duplicate_item.destroy
      end
    end
  end
end
