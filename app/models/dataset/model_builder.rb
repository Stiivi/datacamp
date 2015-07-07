class Dataset
  module Naming
    def model_class_name(dataset_description)
      "#{prefix}#{dataset_description.identifier}".classify
    end

    def full_model_class_name(dataset_description)
      "Kernel::#{model_class_name(dataset_description)}"
    end

    def table_name(dataset_description)
      prefix + dataset_description.identifier
    end

    def prefix
      DatastoreManager.dataset_table_prefix
    end

    def association_name(dataset_description, morphed = false)
      suffix = morphed ? "_morphed" : ""

      :"#{prefix}#{dataset_description.identifier.pluralize}#{suffix}"
    end
  end

  class ModelBuilder
    include Naming

    attr_reader :dataset_description

    def initialize(dataset_description)
      @dataset_description = dataset_description
    end

    def build
      define_model_class
      set_up_model
      set_up_relation

      self
    end

    def define_model_class
      unless Kernel.const_defined?(model_class_name(dataset_description))
        Kernel.const_set(model_class_name(dataset_description), Class.new(Dataset::DatasetRecord))
      end
    end

    def set_up_model
      model_class.dataset = dataset_description
      model_class.establish_connection "#{Rails.env}_data"
      model_class.table_name = table_name(dataset_description)

      model_class.send(:has_many, :dc_updates, class_name: 'Dataset::DcUpdate', as: :updatable)
    end

    def set_up_relation
      dataset_description.relations.each do |relation|

        left_association = (relation.relationship_dataset_description.identifier < dataset_description.identifier)
        if relation.respond_to?(:morph) && relation.morph?
          model_class.send(:has_many, (left_association ? :dc_relations_left_morphed : :dc_relations_right_morphed),
                           class_name: 'Dataset::DcRelation',
                           as: (left_association ? :relatable_left : :relatable_right),
                           conditions: {morphed: true}
          )
          model_class.send(:has_many,
                           association_name(relation.relationship_dataset_description),
                           through: (left_association ? :dc_relations_left_morphed : :dc_relations_right_morphed),
                           source: (left_association ? :relatable_right : :relatable_left),
                           source_type: full_model_class_name(relation.relationship_dataset_description)
          )
        else
          model_class.send(:has_many, (left_association ? :dc_relations_left : :dc_relations_right),
                           class_name: 'Dataset::DcRelation',
                           as: (left_association ? :relatable_left : :relatable_right),
                           conditions: {morphed: false}
          )
          model_class.send(:has_many,
                           association_name(relation.relationship_dataset_description),
                           through: (left_association ? :dc_relations_left : :dc_relations_right),
                           source: (left_association ? :relatable_right : :relatable_left),
                           source_type: full_model_class_name(relation.relationship_dataset_description)
          )
        end
        model_class.reflect_on_all_associations.delete_if{ |a| a.name =~ /^dc_/ }.map do |reflection|
          model_class.accepts_nested_attributes_for(reflection.name)
        end
      end
    end

    def model_class
      @model_class ||= full_model_class_name(dataset_description).constantize
    end
    alias_method :dataset_record_class, :model_class
  end
end
