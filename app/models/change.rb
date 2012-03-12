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
  
  
  def dataset_description_identifier
    dataset_description.present? ? dataset_description.identifier : I18n.t('n_a')
  end
  
  def user_name
    user.present? ? user.name : I18n.t('n_a')
  end
end
