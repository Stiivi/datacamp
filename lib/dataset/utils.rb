class Dataset::Utils

  # Initialize dataset if not exist

  def self.initialize_dataset(dataset_name, debug_output=false)
    if Dataset::DatasetRecord.connection.table_exists?("ds_#{dataset_name}") && !DatasetDescription.find_by_identifier(dataset_name)
      puts "initializing #{dataset_name}"     if debug_output
      dataset_base = Dataset::Base.build_from_identifier(dataset_name)
      dataset_base.add_primary_key
      dataset_base.add_system_columns
      puts 'finished transormation'   if debug_output
      puts dataset_base.errors        if debug_output
      dataset_base.create_description!
      puts 'finished creating dataset description'  if debug_output
      puts '--------'                 if debug_output
    end
    DatasetDescription.find_by_identifier(dataset_name)
  end

  # Reload dataset

  def self.reload_dataset(dataset_description)
    Dataset::Base.build_from_dataset_description(dataset_description)
  end

  # Create relations
  def self.create_relation(dataset_1, dataset_2, morph = nil)
    if morph.nil?
      Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(dataset_1.id, dataset_2.id)
    else
      Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id_and_morph(dataset_1.id, dataset_2.id, morph)
    end
  end

end