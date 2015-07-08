class PopulateRecordTypeInFavorite < ActiveRecord::Migration
  def up
    Favorite.find_each do |favorite|
      Favorite.where(id: favorite.id).update_all(record_type: record_type_from_dataset(favorite.dataset_description))
    end
  end

  def down
    Favorite.update_all(record_type: nil)
  end

  private

  def record_type_from_dataset(dataset_description)
    if dataset_description
      klass = dataset_description.dataset_model
      klass.to_s if klass
    end
  end
end
