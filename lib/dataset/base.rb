# -*- encoding : utf-8 -*-
class Dataset::Base

  include ::Dataset::Transformations

  attr_reader :errors, :description, :derived_fields #:dataset_record_class, :derived_fields
  cattr_reader :system_columns, :prefix

  @errors = []
  @@prefix = DatastoreManager.dataset_table_prefix

  @@system_columns = {
    :created_at     => :datetime,
    :updated_at     => :datetime,
    :created_by     => :string,
    :updated_by     => :string,
    :record_status  => :string,
    :quality_status => :string,
    :batch_id       => :integer,
    :validity_date  => :date,
    :is_hidden      => :boolean
  }

  ####################################################################################
  # Basic Initializer Method

  def self.build_from_dataset_description(dataset_description)
    new(dataset_description)
  end

  def self.build_from_identifier(identifier)
    new(DatasetDescription.new(identifier: identifier))
  end

  class << self
    private :new
  end

  def initialize(dataset_description)
    @description = dataset_description

    # Initialize instance variables
    @errors = []

    # Setup DatasetRecord based on description
    Kernel.const_set((@@prefix + @description.identifier).classify, Class.new(Dataset::DatasetRecord)) unless dataset_record_class
    dataset_record_class.dataset = self
    dataset_record_class.establish_connection Rails.env + "_data"
    table_name = @@prefix + @description.identifier
    dataset_record_class.table_name = table_name

    dataset_record_class.send(:has_many, :dc_updates, class_name: 'Dataset::DcUpdate', as: :updatable)
    if Relation.table_exists?
      @description.relations.each do |relation|
        next if relation.id.blank?

        left_association = (relation.relationship_dataset_description.identifier < description.identifier)
        if relation.respond_to?(:morph) && relation.morph?
          dataset_record_class.send( :has_many, (left_association ? :dc_relations_left_morphed : :dc_relations_right_morphed),
                                     class_name: 'Dataset::DcRelation',
                                     as: (left_association ? :relatable_left : :relatable_right),
                                     conditions: {morphed: true}
                                   )
          dataset_record_class.send( :has_many,
                                    (@@prefix + relation.relationship_dataset_description.identifier.pluralize + '_morphed').to_sym,
                                    through: (left_association ? :dc_relations_left_morphed : :dc_relations_right_morphed),
                                    source: (left_association ? :relatable_right : :relatable_left),
                                    source_type: "Kernel::" + (@@prefix + relation.relationship_dataset_description.identifier).classify
                                  )
        else
          dataset_record_class.send( :has_many, (left_association ? :dc_relations_left : :dc_relations_right),
                                     class_name: 'Dataset::DcRelation',
                                     as: (left_association ? :relatable_left : :relatable_right),
                                     conditions: {morphed: false}
                                   )
          dataset_record_class.send( :has_many,
                                    (@@prefix + relation.relationship_dataset_description.identifier.pluralize).to_sym,
                                    through: (left_association ? :dc_relations_left : :dc_relations_right),
                                    source: (left_association ? :relatable_right : :relatable_left),
                                    source_type: "Kernel::" + (@@prefix + relation.relationship_dataset_description.identifier).classify
                                  )
        end
        dataset_record_class.reflect_on_all_associations.delete_if{ |a| a.name =~ /^dc_/ }.map do |reflection|
          dataset_record_class.accepts_nested_attributes_for(reflection.name)
        end
      end
    end

    def dataset_record_class.find(*args)
      select_columns = ", " + dataset.derived_fields.map { |field, value| "#{value} as #{field}" }.join(",") if dataset.has_derived_fields?

      conditions = {}
      # TODO should display only records with ok status

      with_scope(select(select_columns).where(conditions)) do
        super(*args)
      end
    end

    # Get connection from model
    @connection = Dataset::DatasetRecord.connection

    # Add derived fields
    @derived_fields = Hash.new
    @description.derived_field_descriptions.each do |derived_field|
      @derived_fields[derived_field.identifier.to_sym] = derived_field.derived_value
    end
  end

  def dataset_record_class
    @dataset_record_class ||= ('Kernel::' + (@@prefix + @description.identifier).classify).constantize
    rescue
      return false
  end

  def has_derived_fields?
    !@derived_fields.empty?
  end


  ####################################################################################
  # Shortcuts

  def table_name
    dataset_record_class.table_name
  end

  def table_exists?
    # we cannot user dataset_record_class.table_exists? because it returns wrong results because of cache
    dataset_record_class.connection.tables.include?(table_name)
  end

  def to_param
    @description.to_param
  end

  def dataset_description
    description
  end

  def dataset_description=(dataset_description)
    @description = dataset_description
  end


  ####################################################################################
  # "Finder" method - to retrieve all tables

  def self.find_tables *args
    args = args.extract_options!
    tables = Dataset::DatasetRecord.connection.select_all('show tables').collect { |r| r.values[0] }
    if args[:prefix]
      tables = tables.find_all { |r| r =~ /^#{args[:prefix]}_/ }
    end
    if args[:prefix_not]
      tables = tables.delete_if { |r| r =~ /^#{args[:prefix_not]}_/ }
    end
    return tables
  end

  ####################################################################################
  # Table information & manipulation

  def has_column? column
    return false unless table_exists?
    @columns ||= @connection.columns table_name
    @columns.collect{|col|col.name}.include? column.to_s
  end

  def has_pk?
    has_column? "_record_id"
  end

  def add_column name, type
    @connection.add_column table_name, name, type
  end

  def connection
    @connection
  end

  def add_error(error)
    @errors << error
  end
end
