require 'dataset/utils'

module DatasetHelpers

  def initialize_datasets(dataset_names, relations)
    datasets = {}
    dataset_names.each do |dataset_name|
      datasets[dataset_name] = Dataset::Utils.initialize_dataset(dataset_name)
    end
    relations.each do |relation|
      Dataset::Utils.create_relation(datasets[relation[0]], datasets[relation[1]], relation[2])
    end
    datasets.values.each do |dataset|
      Dataset::Utils.reload_dataset(dataset)
    end
  end

end