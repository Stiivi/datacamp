class Dataset
  class TableTransformer
    include Dataset::Transformations

    def initialize(dataset_description)
      @description = dataset_description
      @connection = dataset_description.dataset_model.connection
      @errors = []
    end

    def has_column?(column)
      return false unless table_exists?
      @columns ||= @connection.columns table_name
      @columns.collect{|col|col.name}.include? column.to_s
    end

    def has_pk?
      has_column? "_record_id"
    end

    def table_exists?
      @description.dataset_model.table_exists?
    end

    def table_name
      @description.dataset_model.table_name
    end

    def system_columns
      Dataset::Base.system_columns
    end

    def dataset_description
      @description
    end

    def dataset_description=(dataset_description)
      @description = dataset_description
    end

    def add_error(error)
      @errors << error
    end

    def connection
      @connection
    end
  end
end