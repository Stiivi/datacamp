class Access < ActiveRecord::Base
  
  belongs_to :session
  belongs_to :dataset_description
  
  def self.find_popular_records
    columns = "id, dataset_description_id, record_id, count(record_id) count"
    results = self.select(columns).where("record_id IS NOT NULL").order("count desc").group("dataset_description_id, record_id").limit(5)
  end
  
  def record
    return false unless (dataset_description and record_id)
    peer = Dataset::Base.new(dataset_description).dataset_record_class
    record = peer.find_by_id(record_id)
  end
end