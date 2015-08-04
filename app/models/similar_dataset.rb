class SimilarDataset < ActiveRecord::Base
  belongs_to :dataset_description_source,
             foreign_key: :similar_source_id,
             class_name: 'DatasetDescription'

  belongs_to :dataset_description_target,
             foreign_key: :similar_target_id,
             class_name: 'DatasetDescription'
end
