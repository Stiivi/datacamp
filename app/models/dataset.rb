module Dataset
  Column = Struct.new(:name, :type)

  COLUMN_TYPES = [:string, :integer, :date, :text, :decimal, :boolean]

  SYSTEM_COLUMNS = [
      Column.new(:created_at,     :datetime),
      Column.new(:updated_at,     :datetime),
      Column.new(:created_by,     :string),
      Column.new(:updated_by,     :string),
      Column.new(:record_status,  :string),
      Column.new(:quality_status, :string),
      Column.new(:batch_id,       :integer),
      Column.new(:validity_date,  :date),
      Column.new(:is_hidden,      :boolean),
  ]

  DATASET_TABLE_PREFIX = 'ds_'

  SYSTEM_TABLES = [
      'dc_relations', 'dc_updates', 'schema_migrations'
  ]

  CONNECTION = Dataset::DatasetRecord.connection

  RecordStatus = Status.new(
      ['absent', 'loaded', 'new', 'published', 'suspended', 'deleted', 'morphed']
  )

end
