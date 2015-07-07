class Dataset

  class ModelBuilder
    attr_reader :dataset_description

    def initialize(dataset_description)
      @dataset_description = dataset_description
      @prefix = DatastoreManager.dataset_table_prefix
    end

    def build
      define_model_class
      set_up_model
      set_up_relation

      self
    end

    def define_model_class
      unless Kernel.const_defined?(model_class_name)
        Kernel.const_set(model_class_name, Class.new(Dataset::DatasetRecord))
      end
    end

    def set_up_model
      model_class.dataset = dataset_description
      model_class.establish_connection "#{Rails.env}_data"
      model_class.table_name = @prefix + @dataset_description.identifier

      model_class.send(:has_many, :dc_updates, class_name: 'Dataset::DcUpdate', as: :updatable)
    end

    def set_up_relation
      dataset_description.relations.each do |relation|

        left_association = (relation.relationship_dataset_description.identifier < dataset_description.identifier)
        if relation.respond_to?(:morph) && relation.morph?
          model_class.send( :has_many, (left_association ? :dc_relations_left_morphed : :dc_relations_right_morphed),
                                     class_name: 'Dataset::DcRelation',
                                     as: (left_association ? :relatable_left : :relatable_right),
                                     conditions: {morphed: true}
          )
          model_class.send( :has_many,
                                     (@prefix + relation.relationship_dataset_description.identifier.pluralize + '_morphed').to_sym,
                                     through: (left_association ? :dc_relations_left_morphed : :dc_relations_right_morphed),
                                     source: (left_association ? :relatable_right : :relatable_left),
                                     source_type: "Kernel::" + (@prefix + relation.relationship_dataset_description.identifier).classify
          )
        else
          model_class.send( :has_many, (left_association ? :dc_relations_left : :dc_relations_right),
                                     class_name: 'Dataset::DcRelation',
                                     as: (left_association ? :relatable_left : :relatable_right),
                                     conditions: {morphed: false}
          )
          model_class.send( :has_many,
                                     (@prefix + relation.relationship_dataset_description.identifier.pluralize).to_sym,
                                     through: (left_association ? :dc_relations_left : :dc_relations_right),
                                     source: (left_association ? :relatable_right : :relatable_left),
                                     source_type: "Kernel::" + (@prefix + relation.relationship_dataset_description.identifier).classify
          )
        end
        model_class.reflect_on_all_associations.delete_if{ |a| a.name =~ /^dc_/ }.map do |reflection|
          model_class.accepts_nested_attributes_for(reflection.name)
        end
      end
    end

    # TODO move somewhere else!
    def to_param
      dataset_description.to_param
    end

    def model_class
      @model_class ||= full_model_class_name.constantize
    end
    alias_method :dataset_record_class, :model_class

    private

    def model_class_name
      "#{@prefix}#{dataset_description.identifier}".classify
    end

    def full_model_class_name
      "Kernel::#{model_class_name}"
    end
  end
end
