# -*- encoding : utf-8 -*-
module Dataset::Transformations

  def connection
    raise NotImplemented
  end

  def dataset_description
    raise NotImplemented
  end

  def dataset_description=(dataset_description)
    raise NotImplemented
  end

  def system_columns
    raise NotImplemented
  end

  def add_error(error)
    raise NotImplemented
  end

  def has_column?(column)
    raise NotImplemented
  end

  def table_exists?(table_name)
    raise NotImplemented
  end

  def table_name
    raise NotImplemented
  end

  def dataset_record_class
    raise NotImplemented
  end

  ######################################################################
  # This method takes existing table, changes the name and adds system
  # columns.

  def transform!
    unless connection.table_exists?(dataset_description.identifier)
      add_error("Can't transform table: There's no #{dataset_description.identifier} table.")
      return false
    end

    # Change name of the table according to naming convention
    connection.rename_table dataset_description.identifier, table_name

    add_primary_key
    add_system_columns

    true
  end

  def add_primary_key
    # 1. Remove existing PK (keep id column, but remove auto_increment and stuff)
    if has_column?('id')
      # FIXME: what if id column was not integer???
      # TODO: why do we remove auto increment?
      # TODO: why do we even rename id column to _record_id ??
      connection.change_column table_name, :id, :integer, :auto_increment => false, :null => true
      begin
        connection.execute "ALTER TABLE #{table_name} DROP PRIMARY KEY"
      rescue
      end
    end
    connection.add_column table_name, :_record_id, :primary_key unless has_column?('_record_id')
  end

  def add_system_columns
    success = true
    system_columns.each do |column, type|
      if has_column? column
        add_error("Table already has column #{column}, which is one of the system columns.")
        success = false
      end
    end
    return false unless success
    connection.execute "ALTER TABLE #{table_name} ADD COLUMN (" + system_columns.map { |column, type| "#{connection.quote_column_name(column)} #{connection.type_to_sql(type)}" }.join(', ') + ")"
  end


  ######################################################################
  # Creates description for existing table

  def create_description!
    # FIXME: remove checking for prefixes
    description = DatasetDescription.find_or_initialize_by_identifier table_name.sub('ds_', '')
    description.title = description.identifier.sub('ds_', '').humanize.titleize
    description.save(validate: false)

    self.dataset_description = description

    dataset_record_class.columns.each do |column|
      create_description_for_column(column)
    end
  end

  def create_description_for_column(column)
    # FIXME: this should be handled outside of this method. this method
    # should describe ANY column, just based in it's name - it is string
    # operation
    if !(system_columns.keys + [:_record_id]).include?(column.name.to_sym)

      # FIXME: rewrite this
      field_description = dataset_description.field_descriptions.find_or_initialize_by_identifier(column.name.to_s)
      field_description.title = column.name.to_s.humanize.titleize
      # FIXME: not localizable!
      field_description.category = "Other"
      field_description.save(validate: false)
    end
  end

  ######################################################################
  # Turns description into a table

  def setup_table
    unless dataset_description.is_a? DatasetDescription
      raise "Description doesn't exist for this table, can't turn it into table."
    end

    if table_exists?
      return false
    end

    dataset_description.save(validate: false)

    connection.create_table(dataset_description.identifier, :options => 'DEFAULT CHARSET=utf8', :primary_key => "_record_id") {}

    transform!

    dataset_description.field_descriptions.each do |fd|
      create_column_for_description(fd)
    end
  end

  def create_column_for_description(fd)
    data_type = fd.data_type || "string"

    manager = DatastoreManager.manager_with_default_connection
    manager.add_dataset_field(dataset_description.identifier, fd.identifier, data_type)
  end
end
