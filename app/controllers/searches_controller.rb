class SearchesController < ApplicationController

  ########################################################################
  # Search/Create -> Creates new search spicified by one of the following
  # parameters:
  # 1. query_string -> global search for one string. This way only 5 results
  #                    from each dataset are loaded. After search user is redi-
  #                    rected to search/show with results.
  # 2. predicates   -> dataset-wide search specified by predicates array. This
  #                    search will include all results from a dataset. User
  # =>                 will be redirected back to dataset/view.

  def create
    search_params = params[:search] || {}
    if search_params[:predicates]
      query = SearchQuery.query_with_predicates(create_predicates_from_hash(search_params[:predicates]), :scope => "dataset", :object => search_params[:dataset])
      search = Search.create(:query => query, :search_type => 'predicates', :session => @current_session)

      if search_params[:dataset].present?
        redirect_to dataset_path(DatasetDescription.find_by_identifier(search.query.object), :search_id => search.id)
      else
        redirect_to search_path(search)
      end
    else
      redirect_to datasets_path, :notice => 'Something went wrong...'
    end
  end

  def predicate_rows
    @dataset_description = DatasetDescription.find_by_identifier(params[:identifier])
    render :predicate_rows, layout: false
  end

  ########################################################################
  # Quick search using Sphinx. If Sphinx search engine couldn't be used
  # redirect to regular search.
  def quick
    query = params[:query_string]
    engine = SphinxSearchEngine.new
    search = engine.create_search_with_string(query)
    redirect_to search_path(search, :disabled_descriptions => params[:disabled_descriptions])
  end

  def show
    @search = Search.find(params[:id])
    @disabled_descriptions = params[:disabled_descriptions]

    @results = {}
    dds = DatasetDescription

    dds = dds.where('id NOT IN(?)', params[:disabled_descriptions]) if params[:disabled_descriptions]
    dds = dds.where(category_id: params[:category_id]) if params[:category_id] # TODO: test filter by category_id

    @results = {}
    dds.active.includes([
        :category,
        {:relations => :relationship_dataset_description},
        :derived_field_descriptions,
        {:field_descriptions_for_search => [:translations, :data_format] }]
    ).each do |dataset_description|
      begin
        dataset_results = dataset_description.dataset.dataset_record_class.search @search.query_string, :limit => 5, :conditions => { record_status: DatastoreManager.record_statuses[2] }
        @results[dataset_description.category] ||= {}
        @results[dataset_description.category][dataset_description] = dataset_results if dataset_results.present?
      rescue
        # TODO: why is this swallowing everything?
      end
    end
  end

  protected

  def create_predicates_from_hash(hash)
    hash.collect { |predicate|
      if predicate[:operator].present? && predicate[:value].present?
        SearchPredicate.create({:scope => "record", :search_field => predicate[:field], :operator => predicate[:operator], :argument => predicate[:value]})
      end
    }.select { |p| p.present? }
  end
end
