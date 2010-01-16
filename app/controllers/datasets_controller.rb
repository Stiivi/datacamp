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
  
  before_filter :prepare_filters, :only => [:show]
  # privilege_required :data_management, :update
  
  helper_method :has_filters?
  
  def index
    @all_dataset_descriptions = DatasetDescription.find(:all, :conditions => "is_active = 1")
    @dataset_descriptions = @all_dataset_descriptions.group_by(&:category)
    respond_to do |wants|
      wants.html
      wants.xml { render :xml => @all_dataset_descriptions }
    end
  end
  
  def show    
    @dataset_description = DatasetDescription.find_by_id!(params[:id])
    @field_descriptions  = @dataset_description.visible_field_descriptions
    @dataset             = @dataset_description.dataset
    @dataset_class       = @dataset.dataset_record_class
    
    unless @dataset_class.table_exists?
      logger.error "Dataset table doesn't exist for #{@dataset_description.title} (#{@dataset_class.table_name})"
      flash[:error] = I18n.t("dataset.internal_dataset_error", :title => @dataset_description.title)
      return redirect_to datasets_path
    end
    
    unless @dataset.has_pk?
      logger.error "Dataset is missing PK _record_id: #{@dataset_description.title} (#{@dataset_description.identifier})"
      flash[:error] = I18n.t("dataset.internal_dataset_error", :title => @dataset_description.title)
      return redirect_to datasets_path
    end
    
    # Comments
    load_comments
    
    # Favorite if there's one
    @favorite = current_user.favorite_for!(@dataset_description, @record)
    
    select_options = create_options_for_select
    
    @records             = @dataset_class.paginate(select_options)
    
    # Extra javascripts
    add_javascript('datasets/search.js')
    
    respond_to do |wants|
      wants.html { render :action => "show" }
      wants.xml { render :xml => @records }
      wants.json { render :json => @records }
      wants.js do
        return render :template => "datasets/admin/show" if current_user && current_user.has_privilege?(:data_management)
        return render :action => "show" 
      end
    end
  end
  
  # Batch update
  def update
    @dataset_description = DatasetDescription.find_by_id(params[:id])
    @record_class        = @dataset_description.dataset.dataset_record_class
    unless params[:record]
      flash[:error] = I18n.t("dataset.not_enough_records_selected")
      return redirect_to(dataset_path(@dataset_description)) 
    end
    params[:record].each do |record|
      record = @record_class.find_by_record_id(record)
      if record
        unless params[:status].blank?
          record.record_status = params[:status]
        end
        unless params[:quality].blank?
          record.quality_status = params[:quality]
        end
        record.save(false)
      end
    end
    flash[:notice] = I18n.t("dataset.batch_updated", :count => params[:record].size)
    return redirect_to(dataset_path(@dataset_description))
  end
  
  def sitemap
    # TODO implement .. somehow ..
  end
  
  protected
  
  def create_options_for_select
    ### Loading & Pagination & stuff
    per_page = current_user ? current_user.records_per_page : RECORDS_PER_PAGE
    
    ### Options for pagination
    select_options = { :page => params[:page], :per_page => per_page }
    select_options[:conditions] = {}
    
    ### Options for order
    sort_direction = params[:dir] || "asc"
    select_options[:order] = "#{params[:sort]} IS NULL #{sort_direction}, #{params[:sort]} #{sort_direction}" if params[:sort]
    
    ### Options for search
    if params[:search_id]
      search_object = Search.find_by_id!(params[:search_id])
      @search_predicates = search_object.query.predicates
      search_query_id = search_object.query.id
      select_options[:from] = "#{SearchResult.connection.current_database}.search_results"
      select_options[:joins] = "LEFT JOIN #{@dataset_class.table_name} ON search_results.record_id = #{@dataset_class.table_name}._record_id"
      select_options[:select] = "#{@dataset_class.table_name}.*"
      select_options[:conditions][:"search_results.search_query_id"] = search_query_id
      select_options[:total_entries] = nil
    else
      select_options[:from] = @dataset_class.table_name
    end
    
    ### Options for filter
    if @filters
      filters = @filters.find_all{|key,value|!value.blank?}
      filters.each do |key, value|
        select_options[:conditions][key] = value
      end
      # raise select_options.to_yaml
    end
    
    ### Filtering for those with insufficient privileges
    unless current_user.has_privilege?(:view_hidden_records)
      select_options[:finder] = 'active'
    end
    
    select_options
  end
  
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
end