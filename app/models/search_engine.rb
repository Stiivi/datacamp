class SearchEngine
  def search(datasets, search)
    queries = datasets.each_with_object([]) do |dataset, queries|
      queries << build_sphinx_query(dataset, search).to_sql
      queries << Riddle::Query.meta # for total matches count
    end

    results = ThinkingSphinx::Connection.take do |connection|
      connection.query_all *queries
    end

    output = []

    results.each_slice(2).zip(datasets).each do |data, dataset|
      results, meta = data
      ids = results.map { |result| result['sphinx_internal_id'] }
      records = dataset.find_by_record_ids(ids)
      total = meta.to_a.detect { |row| row['Variable_name'] == 'total' }['Value']

      output << WillPaginate::Collection.create(1, 5, total) do |pager|
        pager.replace(records)
      end
    end

    output
  end

  private

  def build_sphinx_query(dataset, search)
    Riddle::Query::Select.new.
      from(index_name(dataset)).values('sphinx_internal_id').
      matching(search.query_string + '@record_status published').
      where(sphinx_deleted: false).
      limit(5).
      with_options(max_matches: 1000)
  end

  def index_name(dataset)
    dataset.to_s.underscore.gsub('/', '_') + '_core'
  end
end
