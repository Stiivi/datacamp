# -*- encoding : utf-8 -*-
class Change < ActiveRecord::Base
  belongs_to :dataset_description
  belongs_to :user
  
  def dataset_description_identifier
    dataset_description.present? ? dataset_description.identifier : I18n.t('n_a')
  end
  
  def user_name
    user.present? ? user.name : I18n.t('n_a')
  end
end
