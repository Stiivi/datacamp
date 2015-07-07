class Dataset
  class TableTransformer
    include Dataset::Transformations

    def initialize(dataset_description)
      @description = dataset_description
      @connection = dataset_description.dataset_record_class.connection
      @errors = []
    end

    def has_column? column
      return false unless table_exists?
      @columns ||= @connection.columns table_name
      @columns.collect{|col|col.name}.include? column.to_s
    end

    def has_pk?
      has_column? "_record_id"
    end

    def table_exists?
      @description.dataset_record_class.table_exists?
    end

    def table_name
      @description.dataset_record_class.table_name
    end

    def system_columns
      Dataset::Base.system_columns
    end

    def dataset_description
      @description
    end
  end
end