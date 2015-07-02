# -*- encoding : utf-8 -*-
class Change < ActiveRecord::Base
  belongs_to :dataset_description
  belongs_to :user
  
  serialize :dataset_description_cache
  serialize :change_details
  
  DATASET_CREATE    = 'dataset_create'
  DATASET_UPDATE    = 'dataset_update'
  DATASET_DESTROY   = 'dataset_destroy'
  
  RECORD_CREATE     = 'record_create'
  RECORD_UPDATE     = 'record_update'
  RECORD_DESTROY    = 'record_destroy'
  
  BATCH_INSERT      = 'batch_insert'
  BATCH_UPDATE      = 'batch_update'

  def self.store_batch_update(import_file, params)
    create!(
        change_type: Change::BATCH_INSERT,
        user: params.fetch(:current_user),
        change_details: {
            update_conditions: {
                _record_id: params.fetch(:saved_ids)
            },
            update_count: params.fetch(:count),
            batch_file: import_file.path_file_name
        },
        dataset_description: import_file.dataset_description
    )
  end

  def dataset_description_identifier
    dataset_description.present? ? dataset_description.identifier : I18n.t('n_a')
  end
  
  def user_name
    user.present? ? user.email : I18n.t('n_a')
  end
end
