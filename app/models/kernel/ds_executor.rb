class Kernel::DsExecutor < Dataset::DatasetRecord

  def self.store_executor(params)
    executor = Kernel::DsExecutor.find_or_initialize_by_name_and_city(params.fetch(:name), params.fetch(:city))
    executor.update_attributes!(params)
    executor
  end

  def self.suspend_all
    update_all(record_status: Dataset::RecordStatus.find(:suspended))
  end

  def self.publish_with_ids(ids)
    where(_record_id: ids).update_all(record_status: Dataset::RecordStatus.find(:published))
  end
end