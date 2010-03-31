module Dataset::Transformations
  
  ######################################################################
  # This method takes existing table, changes the name and adds system
  # columns.
  
  def transform!
  	# FIXME: use datatore manager: fix_dataset_metadata,check_missing_dataset_metadata, create_dataset_as_copy_of_tabledataset_exists

    # Check if the table exists in schema
	# FIXME: this does not work correctly
    unless @connection.table_exists? @description.identifier
      @errors << "Can't transform table: There's no #{@description.identifier} table."
      return false
    end
    
    # Change name of the table according to naming convention
    @connection.rename_table @description.identifier, table_name
    
    # Add primary key
  	# FIXME: use datatore manager: fix_dataset_metadata,check_missing_dataset_metadata, create_dataset_as_copy_of_tabledataset_exists
    add_primary_key
    
    # Add system columns
  	# FIXME: use datatore manager: fix_dataset_metadata,check_missing_dataset_metadata, create_dataset_as_copy_of_tabledataset_exists
    add_system_columns
    
    # Return true
    true
  end
  
  def add_primary_key
  	# FIXME: use datatore manager: fix_dataset_metadata,check_missing_dataset_metadata, create_dataset_as_copy_of_tabledataset_exists
  
    # 1. Remove existing PK (keep id column, but remove auto_increment and stuff)
    if self.has_column?("id")
      id_column = @connection.columns(table_name).find {|c|c.name == "id" }

      # FIXME: what if id column was not integer???
      @connection.change_column table_name, :id, :integer, :auto_increment => false, :null => true
      begin
        @connection.execute "ALTER TABLE #{table_name} DROP PRIMARY KEY"
      rescue
      end
    end
    # FIXME: get constant from datastore manager!
    @connection.add_column table_name, :_record_id, :primary_key unless self.has_column?("_record_id")
    
    # 2. Create _record_id, which is PK with auto_increment
    # @connection.add_column table_name, :_record_id, :primary_key
  end
  
  def add_system_columns
  	# FIXME: use datatore manager: fix_dataset_metadata,check_missing_dataset_metadata, create_dataset_as_copy_of_tabledataset_exists
    success = true
    system_columns.each do |column, type|
      if has_column? column
        @errors << "Table already has column #{column}, which is one of the system columns."
        success = false
      end
    end
    return false unless success
    @connection.execute "ALTER TABLE #{table_name} ADD COLUMN (" + system_columns.map { |column, type| "#{@connection.quote_column_name(column)} #{@connection.type_to_sql(type)}" }.join(', ') + ")"
  end
  
  ######################################################################
  # Return table to state before transform!
  
  def revert!
	# FIXME: Remove this method, it is no more necessary as we are creating copies of a table
    unless @connection.table_exists? table_name
      @errors << "Can't transform table: There's no #{table_name} table."
      return false
    end
    
    # Remove description
    DatasetDescription.find_or_create_by_identifier(table_name).destroy
    
    # Change name of the table if needed
    if table_name =~ /^ds_/
      new_table_name = "#{table_name}".sub('ds_', '')
      @connection.rename_table table_name, new_table_name
      @dataset_record_class.set_table_name new_table_name
    end
    
    system_columns.each do |column, type|
      begin
        @connection.remove_column table_name, column
      rescue Exception => e
        next
      end      
    end
  end
  
  ######################################################################
  # Creates description for existing table
  
  def create_description!
    # Create, save & associate with this object a description
	# FIXME: remove checking for prefixes
    @description = DatasetDescription.find_or_initialize_by_identifier table_name.sub('ds_', '')
    category_name = table_name.sub('ds_', '').split('_')[0].humanize
    # @description.category   = DatasetCategory.find_or_create_by_title(category_name)
    @description.title      = @description.identifier.sub('ds_', '').humanize.titleize
    @description.save(false)
    
    @dataset_record_class.columns.each do |column|
      create_description_for_column(column)
    end
  end
  
  def create_description_for_column(column)

    # FIXME: this should be handled outside of this method. this method
    # should describe ANY column, just based in it's name - it is string
    # operation
    return if (system_columns.keys + [:_record_id]).include? column.name.to_sym

	# FIXME: rewrite this
    field_description = @description.field_descriptions.find_or_initialize_by_identifier(column.name.to_s)
    field_description.title = column.name.to_s.humanize.titleize

    # if column.name.to_s.split("_").length > 1 && @dataset_record_class.columns.find_all{ |c| c.name.split("_").length > 1 && c.name.split("_")[0] == column.name.split("_")[0] }.length > 1
    #  prefix = column.name.to_s.split("_")[0]
    #  field_description.category = prefix.humanize.titleize
    #  field_description.title = column.name.sub("#{prefix}_", "").humanize.titleize
    #else
	  # FIXME: not localizable!
      field_description.category = "Other"
      # field_description.weight = 100
    # end
    
    field_description.save(false)
  end
  
  ######################################################################
  # Turns description into a table
  
  def setup_table
	# FIXME: use datastore manager dataset_exists?(identifier) and create_dataset(identifier)
    # FIXME: give more sane name to this method, such as: create_dataset(_table) ;-)
    unless @description.is_a? DatasetDescription
      raise "Description doesn't exist for this table, can't turn it into table."
    end
    
    # False if it exists
    if table_exists?
      return false
    end
    
    @description.save(false)
    
    @connection.create_table(@description.identifier, :options => 'DEFAULT CHARSET=utf8', :primary_key => "_record_id") {}
    
    transform!
    
    @description.field_descriptions.each do |fd|
      create_column_for_description(fd)
    end
  end
  
  def create_column_for_description(fd)
	# FIXME: use datastore manager add_dataset_field(dataset, field, type)
	# FIXME: Default data type should be :string
    # FIXME: This should be stored in some settings mechanism
    # FIXME: derived should be checked before this method!
    default_data_type = "string"
    
    data_type = fd.data_type || default_data_type
    
    manager = DatastoreManager.manager_with_default_connection
    manager.add_dataset_field(self.dataset_description.identifier, fd.identifier, data_type)
  end
end