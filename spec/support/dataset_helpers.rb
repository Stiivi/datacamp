require 'dataset/utils'

module DatasetHelpers

  def initialize_datasets(dataset_names, relations)
    dataset_descriptions = {}
    dataset_names.each do |dataset_name|
      dataset_descriptions[dataset_name] = Dataset::Utils.initialize_dataset(dataset_name)
    end
    relations.each do |relation|
      Dataset::Utils.create_relation(dataset_descriptions[relation[0]], dataset_descriptions[relation[1]], relation[2])
    end
    dataset_descriptions.values.each do |dataset_description|
      dataset_description.reload_dataset_model
    end
  end

end