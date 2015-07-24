# -*- encoding : utf-8 -*-
# Datasets Controller
#
# Copyright:: (C) 2009 Knowerce, s.r.o.
# 
# Author:: Vojto Rinik <vojto@rinik.net>
# Date: Sep 2009
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
  # along with this program.  If not, see <http://www.gnu.org/licenses/>.

class DatasetsController < ApplicationController
  include CommentsLoader

  before_filter :prepare_filters, :only => [:show, :update]
  privilege_required :edit_record, :only => [:update]

  helper_method :has_filters?

  def index
    @only_good = params[:only_good]
    respond_to do |wants|
      wants.html do
        @dataset_categories = DatasetCategory.
          order('dataset_categories.position, dataset_descriptions.position').
          includes(:dataset_descriptions => :translations).
          where('dataset_descriptions.is_active = 1')

        if @only_good
          @dataset_categories.where('dataset_description.bad_quality = false')
        end
      end
      wants.xml { render :xml => DatasetDescription.active }
    end
  end

  def show
    @dataset_description = DatasetDescription.find(params[:id])
    @field_descriptions  = @dataset_description.visible_field_descriptions.includes(:data_format)
    @dataset_class       = @dataset_description.dataset_model
    @title               = @dataset_description.title

    render_404 and return unless @dataset_description.is_active? || has_privilege?(:view_hidden_records)

    @sortable_columns = @dataset_class.columns.map(&:name)

    unless @dataset_class.table_exists?
      logger.error "Dataset table doesn't exist for #{@dataset_description.title} (#{@dataset_class.table_name})"
      flash[:error] = I18n.t("dataset.internal_dataset_error", :title => @dataset_description.title)
      return redirect_to datasets_path
    end

    # Comments
    load_comments

    # Favorite if there's one
    @favorite = current_user.favorite_for!(@dataset_description, @record) if current_user

    # Add pagination stuff to those options
    paginate_options = {max_matches: 10_000}
    params[:page] = nil if params[:page].blank?
    paginate_options[:page] = params[:page] if params[:page]#? params[:page] : nil
    paginate_options[:per_page] = current_user ? current_user.records_per_page : RECORDS_PER_PAGE
    # paginate_options[:total_entries] = ((params[:page].to_i||1)+9) * paginate_options[:per_page]

    # check if sort is valid
    if params[:sort]
      if @sortable_columns.exclude? params[:sort]
        redirect_to dataset_path(@dataset_description) and return
      end
    end

    if params[:sort]
      paginate_options[:order] = sanitize_sort_column(params[:sort], @sortable_columns).to_sym
      paginate_options[:sort_mode] = sanitize_sort_direction(params[:dir]).to_sym
    end
    paginate_options[:conditions], paginate_options[:with], paginate_options[:without] = {},{},{}
    paginate_options[:sphinx_select] = "*"
    sphinx_search = ""
    paginate_options[:match_mode] = :extended
    if @filters
      paginate_options[:conditions] ||= {}
      filters = @filters.find_all{|key,value|!value.blank?}
      filters.each do |key, value|
        paginate_options[:conditions].merge!({key.to_sym => value})
      end
      paginate_options[:conditions].merge!({:record_status => "#{Dataset::RecordStatus.find(:published)}|#{Dataset::RecordStatus.find(:morphed)}"}) unless current_user && current_user.has_privilege?(:power_user)
      # raise select_options.to_yaml
    end
    if params[:search_id].blank?
      sort_direction = sanitize_sort_direction(params[:dir])
      if params[:sort] && params[:page]
        # This ugly thing is here because mysql is lame and doesn't use indexes when there is just an order and a limit on the select (pagination with ordering)...
        total_pages = @dataset_class.count.to_i
        page = params[:page].to_i
        per_page = paginate_options[:per_page].to_i

        @records = @dataset_class.select('*').
            from(prepare_subselect(@dataset_class.table_name, @sortable_columns, params, paginate_options)).
            joins("JOIN `#{@dataset_class.table_name}` `t` on `q`.`_record_id` = `t`.`_record_id`")
        if !current_user || !current_user.has_privilege?(:power_user)
          @records = @records.where('t.record_status in (?)', [Dataset::RecordStatus.find(:published), Dataset::RecordStatus.find(:morphed)])
        elsif @filters
          @dataset_class = @dataset_class.where('t.record_status = ?', @filters['record_status']) if @filters['record_status'].present?
          if @filters['quality_status'].present?
            if @filters['quality_status'] == 'absent'
              @dataset_class = @dataset_class.where('t.quality_status IS NULL OR t.quality_status = ?', @filters['quality_status'])
            else
              @dataset_class = @dataset_class.where('t.quality_status = ?', @filters['quality_status'])
            end
          end
        end
        @records.define_singleton_method(:total_pages) { (total_pages/per_page.to_f).ceil }
        @records.define_singleton_method(:current_page) { page }
        @records.define_singleton_method(:previous_page) { page > 1 ? (page - 1) : nil }
        @records.define_singleton_method(:next_page) { page < total_pages ? (page + 1) : nil }
      else
        if params[:sort]
          @dataset_class = @dataset_class.order("`#{sanitize_sort_column(params[:sort], @sortable_columns)}` #{sort_direction}")
        else
          @dataset_class.order('created_at DESC, _record_id DESC')
        end
        if !current_user || !current_user.has_privilege?(:power_user)
          @dataset_class = @dataset_class.where(:record_status => Dataset::RecordStatus.find(:published))
        elsif @filters
          @dataset_class = @dataset_class.where(:record_status => @filters['record_status']) if @filters['record_status'].present?
          if @filters['quality_status'].present?
            if @filters['quality_status'] == 'absent'
              @dataset_class = @dataset_class.where('quality_status IS NULL OR quality_status = ?', @filters['quality_status'])
            else
              @dataset_class = @dataset_class.where(quality_status: @filters['quality_status'])
            end
          end
        end
        @records = @dataset_class.paginate(:page => params[:page], :per_page => paginate_options[:per_page])
      end
    else
      show_search_results_for_dataset(paginate_options, sphinx_search)
    end

    respond_to do |wants|
      wants.html
      wants.xml  { render :xml  => @records }
      wants.json { render :json => @records }
      wants.js do
        if current_user && current_user.has_privilege?(:power_user)
          render :template => 'datasets/admin/show'
        else
          render :action => 'show'
        end
      end
    end
  end

  def show_search_results_for_dataset(paginate_options, sphinx_search)
    sphinx_search = {options: paginate_options, query: sphinx_search}
    search = Search.find(params[:search_id])
    sphinx_search = @dataset_description.build_sphinx_search(search, sphinx_search) # TODO: move to SearchEngine
    sphinx_search[:options].merge!(populate: true, :conditions => { record_status: Dataset::RecordStatus.find(:published)})
    @records = @dataset_class.search(sphinx_search[:query], sphinx_search[:options])
  end

  # Batch update
  def update
    @dataset_description  = DatasetDescription.find_by_id(params[:id])
    @dataset_class        = @dataset_description.dataset_model

    if params[:record].blank?
      flash[:error] = I18n.t("dataset.not_enough_records_selected")
      return redirect_to(dataset_path(@dataset_description))
    end

    # Conditions for update
    update_conditions = {}

    if params[:selection] == "selected"
      # The easier case. User used checkboxes to choose what
      # records they want to edit.
       update_conditions[:_record_id] = params[:record].map(&:to_i)
       @count_updated = params[:record].count
    elsif params[:selection] == "all"
      if params[:search_id].present?
        # Case when all search matching records should be edited.
        # We wanna get all the ids of matching records and
        # pass them to update statement.

        # FIXME: THIS IS A NO OP!?
      else
        # User has chosen to edit all records and to search is
        # specified. We just won't pass any options to update statement
        # and just update whole dataset.

        @dataset_class = @dataset_class.where(:record_status => @filters['record_status']) if @filters['record_status'].present?
        @dataset_class = @dataset_class.where(:quality_status => @filters['quality_status']) if @filters['quality_status'].present?
        @count_updated = @dataset_class.count
      end
    end

    updates = {}
    updates[:record_status] = params[:status] if params[:status].present?
    updates[:quality_status] = params[:quality] if params[:quality].present?

    # Update attributes (only if using batch edit form)
    if params[:update_attribute].present? && params[:attribute_value].present?
      params[:update_attribute].each do |attr_name|
        updates[attr_name] = params[:attribute_value][attr_name]
      end
    end

    update_count = @dataset_class.update_all(updates, update_conditions)
    Change.create(change_type: Change::BATCH_UPDATE, user: current_user, change_details: {updates: updates, update_conditions: update_conditions, update_count: update_count})

    flash[:notice] = I18n.t("dataset.batch_updated", :count => @count_updated)
    params.delete(:search_id) if params[:search_id].blank? #FIXME: ewww ugly!
    params.delete :page if params[:page].blank?
    redirect_to(dataset_path(@dataset_description, :search_id => params[:search_id], :page => params[:page]))
  end

  def batch_edit
    @dataset_description = DatasetDescription.find_by_id(params[:id])
    @dataset_class        = @dataset_description.dataset_model
    @field_descriptions  = @dataset_description.visible_field_descriptions
  end


  def sitemap
    # TODO implement .. somehow ..
  end

  protected
  def prepare_filters
    if params[:clear_filters]
      @filters = {}
    else
      @filters = params[:filters] || {}
    end
    session[:filters] = @filters
  end

  def has_filters?
    @filters && !@filters.empty?
  end

  def prepare_subselect(table_name, sortable_columns, params, paginate_options)
    subselect_parameters = {
        table_name: table_name,
        sort_by: sanitize_sort_column(params[:sort], sortable_columns),
        sort_direction: sanitize_sort_direction(params[:dir]),
        offset: (params[:page].to_i-1) * paginate_options[:per_page].to_i,
        limit: paginate_options[:per_page].to_i
    }

    "(SELECT `_record_id` from `%{table_name}` ORDER BY `%{table_name}`.`%{sort_by}` %{sort_direction} LIMIT %{offset}, %{limit}) q" % subselect_parameters
  end

  def sanitize_sort_column(column, available_columns)
    available_columns.include?(column) ? column : "_record_id"
  end

  def sanitize_sort_direction(direction)
    direction.to_s.downcase == "desc" ? "desc" : "asc"
  end
end
