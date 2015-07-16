module Dataset
  class ModelBuilder
    include Naming

    attr_reader :dataset_description

    def initialize(dataset_description)
      @dataset_description = dataset_description
    end

    def build
      unless model_defined?
        define_model_class
        set_up_connection
        set_up_model
      end

      assign_dataset
      set_up_relation
      set_up_derived_fields

      model_class
    end

    private

    def model_defined?
      Kernel.const_defined?(model_class_name(dataset_description))
    end

    def define_model_class
      Kernel.const_set(model_class_name(dataset_description), Class.new(Dataset::DatasetRecord))
    end

    def set_up_connection
      model_class.establish_connection "#{Rails.env}_data"
    end

    def assign_dataset
      model_class.dataset = dataset_description
    end

    def set_up_model
      model_class.table_name = table_name(dataset_description)
      model_class.send(:has_many, :dc_updates, class_name: 'Dataset::DcUpdate', as: :updatable)
    end

    def set_up_relation
      dataset_description.relations(true).each do |relation|

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

    def set_up_derived_fields
      model_class.derived_fields = dataset_description.derived_field_descriptions(true).map{ |field| [field.identifier, field.derived_value] }
    end

    def model_class
      @model_class ||= full_model_class_name(dataset_description).constantize
    end
  end
end
