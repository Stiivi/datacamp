module DatasetOperationHelpers
  def set_up_relation(from_dataset, to_dataset)
    from_dataset.relationship_dataset_descriptions << to_dataset
    from_dataset.save!
    from_dataset.reload_dataset
  end
end

RSpec.configure do |config|
  config.include DatasetOperationHelpers
end