class RelationshipDescription < ActiveRecord::Base
  belongs_to :dataset_description
  belongs_to :target_dataset_description
  
  translates :title, :description, :category
  locale_accessor :en, :sk
  
  def self.find(*args)
    self.with_scope(:find => {:order => 'weight asc'}) { super }
  end
  
  def is_to_many
    super ? 'yes' : 'no'
  end
end