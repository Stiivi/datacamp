# -*- encoding : utf-8 -*-
# Dataset Descriptions
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

class DatasetDescriptionsController < ApplicationController
  before_filter :get_dataset_description, :only => [:show,
                                                    :edit,
                                                    :update,
                                                    :destroy,
                                                    :import_settings,
                                                    :setup_dataset,
                                                    :set_visibility,
                                                    :add_primary_key,
                                                    :relations,
                                                    :update_relations,
                                                    :edit_field_description_categories,
                                                    :update_field_description_categories]
  before_filter :load_datasets, :only => [:import, :do_import]
  
  privilege_required :edit_dataset_description
  privilege_required :create_dataset, :only => [:new, :create]
  privilege_required :destroy_dataset, :only => [:destroy]
  
  protect_from_forgery :except => :set_visibility
  
  def index
    @dataset_categories = DatasetCategory.order(:position).includes(:dataset_descriptions)
    @other_descriptions = DatasetDescription.where("category_id IS NULL OR category_id = 0").order(:position).includes(:translations)
    
    respond_to do |format|
      format.html
      format.js
      format.xml  { render :xml => @dataset_descriptions }
    end
  end

  def show
    @dataset = @dataset_description.dataset
    if @dataset.dataset_record_class.table_exists?
      @field_descriptions = @dataset_description.field_descriptions
      @field_description_categories = @dataset_description.field_description_categories
      @other_field_descriptions = @dataset_description.field_descriptions.where('field_description_category_id IS NULL OR field_description_category_id = 0')
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @dataset_description }
      format.js
    end
  end

  def new
    @dataset_description = DatasetDescription.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @dataset_description }
    end
  end

  def edit
    respond_to do |wants|
      wants.html
      wants.js { render :action => "move" }
    end
  end

  def create
    @dataset_description = DatasetDescription.new
    
    create_category_if_needed!
    
    @dataset_description.attributes = params[:dataset_description]
    
    respond_to do |format|
      if @dataset_description.save
        @dataset_description.dataset.setup_table
        flash[:notice] = I18n.t("dataset.created_message")
        format.html {
          return redirect_to(new_dataset_description_path) if params[:commit] == I18n.t("global.save_and_create")
          return redirect_to(@dataset_description) 
        }
        format.xml  { render :xml => @dataset_description, :status => :created, :location => @dataset_description }
        format.js
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @dataset_description.errors, :status => :unprocessable_dataset_description }
        format.js
      end
    end
  end

  def update
    redirect_path = dataset_description_path(@dataset_description)
    if params[:return_to]
      begin
        redirect_path = send "#{params[:return_to]}_dataset_description_path", @dataset_description
      rescue
        redirect_path = params[:return_to]
      end
    end

    create_category_if_needed!
    
    @dataset_description.attributes = params[:dataset_description]
    
    if params[:skip_validations]
      success = @dataset_description.save(:validate => false)
    else
      @dataset_description.save
    end
    
    respond_to do |format|
      if success
        flash[:notice] = 'DatasetDescription was successfully updated.'
        format.html {
          return redirect_to(new_dataset_description_path) if params[:commit] == I18n.t("global.save_and_create")
          return redirect_to(redirect_path)
        }
        format.xml  { head :ok }
        format.js
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @dataset_description.errors, :status => :unprocessable_dataset_description }
        format.js
      end
    end
  end

  def destroy
    @dataset_description.destroy

    respond_to do |format|
      format.html { redirect_to(dataset_descriptions_url) }
      format.xml  { head :ok }
    end
  end
  
  def add_primary_key
    dataset = @dataset_description.dataset
    dataset.add_primary_key
    
    redirect_to @dataset_description
  end
  
  def import_settings
    @all_field_descriptions = @dataset_description.field_descriptions.where(:importable => false).order('importable_column asc').select{|field|!field.is_derived}
    @importable_field_descriptions = @dataset_description.field_descriptions.where(:importable => true).order('importable_column asc')
  end
  
  def import
    
  end
  
  def do_import
    @dataset = Dataset::Base.new(params[:dataset])
    if params[:revert]
      success = @dataset.revert!
    else
      success = @dataset.transform! && @dataset.create_description!
    end
    
    if success
      redirect_to import_dataset_descriptions_path
    else
      render :action => "import"
    end
  end
  
  def setup_dataset
    if request.method == :post
      if @dataset_description.dataset.setup_table
        flash[:notice] = "A new table #{@dataset_description.identifier} was created based on #{@dataset_description.title} description."
      else
        flash[:error] = I18n.t('dataset.cant_setup_dataset', :dataset => @dataset_description.title, :identifier => @dataset_description.identifier)
      end
      redirect_to @dataset_description
    end
  end
  
  def visibility
    @dataset_description = DatasetDescription.find_by_id(params[:id])
  end
  
  def set_visibility
    @dataset_description.field_descriptions.each do |fd|
      if params[:field_description_visible][fd.id.to_s]
        fd.is_visible_in_listing = true
      else
        fd.is_visible_in_listing = false
      end
      fd.save(false)
    end
    
    render :nothing => true
  end
  
  def datastore_status
    # FIXME: use datastore manager (not yet implemented)
    dd = DatasetDescription.find_by_id(params[:id])
    
    @connection = Dataset::DatasetRecord.connection
    begin
      table_desc = TableDescription.new(@connection, dd.dataset.table_name)
    rescue Exception => e
      logger.error e.message
      return redirect_to dd
    end
    
    column_names = table_desc.column_names
    field_names = dd.field_descriptions.collect { |fd| fd.identifier }

    # FIXME: move system_columns to datastore manager (not yet implemented)
    system_columns = Dataset::Base.system_columns

    @missing_columns = Array.new
    @missing_descriptions = Array.new
    @table_name = dd.identifier
    
    dd.field_descriptions.each do |fd|
        # Check if exists
        if not column_names.include?(fd.identifier)
            @missing_columns.push(fd.identifier)
        end
    end
    
    column_names.each do |column_name|
        # Check if exists
        if not field_names.include?(column_name) \
                and not system_columns.include?(column_name.to_sym) \
                and column_name != 'id'
            @missing_descriptions.push(column_name)
        end
    end
    @dataset_description = dd
  end
  
  def update_positions
    update_all_positions(params[:dataset_category].keys, params[:dataset_description])
    render :nothing => true
  end
  
  
  def relations
  end
  
  def update_relations
    if params[:save] && @dataset_description.update_attributes(params[:dataset_description])
      redirect_to relations_dataset_description_path(@dataset_description), :notice => 'Relations successfully updated!'
    elsif params[:add_relation]
      @dataset_description.attributes = params[:dataset_description]
      @dataset_description.relations.build
      render 'relations'
    elsif params[:remove_relation]
      @dataset_description.attributes = params[:dataset_description]
      @dataset_description.relations.delete(@dataset_description.relations.last)
      render 'relations'
    else
      render 'relations', :notice => 'Please select all relevant fields!'
    end
  end

  def edit_field_description_categories
    @field_description_categories = @dataset_description.field_description_categories
  end

  def update_field_description_categories
    if @dataset_description.update_attributes(params[:dataset_description])
      redirect_to @dataset_description, notice: 'success'
    else
      @field_description_categories = @dataset_description.field_description_categories
      render :edit_field_description_categories, notice: 'failure'
    end
  end
  
  private
  def update_all_positions(category_placement, description_placement)
    super(DatasetCategory, category_placement)
    items = DatasetDescription.all
    items.each do |item|
      new_index = description_placement.keys.index(item.id.to_s)
      item.update_attributes(:position => new_index+1, :category_id => description_placement[item.id.to_s]) if new_index
    end
  end
  
  protected
  
  def get_dataset_description
    @dataset_description = DatasetDescription.find_by_id!(params[:id])
  end
  
  def load_datasets
    @dataset_description = DatasetDescription.new
    @unbound_datasets = Dataset::Base.find_tables :prefix_not => "ds"
  end
  
  def init_menu
    @submenu_partial = "data_dictionary"
  end
  
  def create_category_if_needed!
    if params[:dataset_description][:category]
      # Create a new category for this one
      unless params[:dataset_description][:category].blank?
        category = DatasetCategory.find_or_create_by_title(params[:dataset_description][:category])
        category.save(false)
        @dataset_description.category = category
      end
      params[:dataset_description].delete(:category)
    end
  end
end
