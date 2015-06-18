class CreateSimilarDatasets < ActiveRecord::Migration
  def self.up
    create_table :similar_datasets do |t|
      t.integer :similar_source_id
      t.integer :similar_target_id

      t.timestamps
    end
  end

  def self.down
    drop_table :similar_datasets
  end
end
