class DatasetCategoryPreparer
  def self.prepare(category_name, category_id)
    if category_name.present?
      DatasetCategory.find_or_create_by_title!(category_name)
    else
      DatasetCategory.find_by_id(category_id)
    end
  end
end