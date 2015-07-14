class Dataset::Utils

  # Initialize dataset if not exist

  def self.initialize_dataset(dataset_name, debug_output=false)
    if Dataset::DatasetRecord.connection.table_exists?("ds_#{dataset_name}") && !DatasetDescription.where(identifier: dataset_name).exists?
      puts "initializing #{dataset_name}" if debug_output
      result = Dataset::TableToDataset.execute("ds_#{dataset_name}", dataset_name)
      if result.valid?
        puts 'finished transformation' if debug_output
      else
        raise "Dataset '#{dataset_name}' was not initialized, reason: #{result.errors.join(', ')}"
      end
    end
    DatasetDescription.find_by_identifier(dataset_name)
  end

  # Create relations
  def self.create_relation(dataset_1, dataset_2, morph = nil)
    Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id_and_morph(dataset_1.id, dataset_2.id, morph)
  end
end
