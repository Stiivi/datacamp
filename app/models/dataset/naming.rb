module Dataset
  module Naming
    extend self

    def model_class_name(dataset_description)
      "#{prefix}#{dataset_description.identifier}".classify
    end

    def full_model_class_name(dataset_description)
      "Kernel::#{model_class_name(dataset_description)}"
    end

    def table_name(dataset_description)
      table_name_from_identifier(dataset_description.identifier)
    end

    def table_name_from_identifier(identifier)
      if identifier.start_with?(prefix)
        identifier
      else
        prefix + identifier
      end
    end

    def prefix
      DATASET_TABLE_PREFIX
    end

    def association_name(dataset_description, morphed = false)
      suffix = morphed ? "_morphed" : ""

      :"#{prefix}#{dataset_description.identifier.pluralize}#{suffix}"
    end

    def association_name_to_identifier(association_name)
      association_name.to_s.gsub(/#{prefix}|_morphed/,'').pluralize
    end
  end

end