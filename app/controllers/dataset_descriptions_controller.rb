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
  before_filter :dataset_description, :only => [:show,
                                                    :edit,
                                                    :update,
                                                    :destroy,
                                                    :import_settings,
                                                    :setup_dataset,
                                                    :edit_field_description_categories,
                                                    :update_field_description_categories]

  privilege_required :edit_dataset_description
  privilege_required :create_dataset, :only => [:new, :create]
  privilege_required :destroy_dataset, :only => [:destroy]

  protect_from_forgery

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
    if dataset_description.dataset_model.table_exists?
      @field_descriptions = dataset_description.field_descriptions
      @field_description_categories = dataset_description.field_description_categories
      @other_field_descriptions = dataset_description.field_descriptions.where('field_description_category_id IS NULL OR field_description_category_id = 0')
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
    end
  end

  def create
    @dataset_description = DatasetDescription.new

    @dataset_description.attributes = params_with_category

    respond_to do |format|
      if @dataset_description.save
        @dataset_description.create_dataset_table
        flash[:notice] = I18n.t("dataset.created_message")
        format.html { redirect_to new_or_detail_description_path }
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
    dataset_description.attributes = params_with_category

    respond_to do |format|
      if dataset_description.save
        flash[:notice] = 'DatasetDescription was successfully updated.'
        format.html { redirect_to new_or_detail_description_path }
        format.xml  { head :ok }
        format.js
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => dataset_description.errors, :status => :unprocessable_dataset_description }
        format.js
      end
    end
  end

  def destroy
    dataset_description.destroy

    respond_to do |format|
      format.html { redirect_to(dataset_descriptions_path) }
      format.xml  { head :ok }
    end
  end

  def import_settings
    @all_field_descriptions = dataset_description.field_descriptions.where(:importable => false).order('importable_column asc').select{|field|!field.is_derived}
    @importable_field_descriptions = dataset_description.field_descriptions.where(:importable => true).order('importable_column asc')
  end

  def setup_dataset
    if request.method == :post
      if dataset_description.create_dataset_table
        flash[:notice] = "A new table #{@dataset_description.identifier} was created based on #{@dataset_description.title} description."
      else
        flash[:error] = I18n.t('dataset.cant_setup_dataset', :dataset => @dataset_description.title, :identifier => @dataset_description.identifier)
      end
      redirect_to dataset_description
    end
  end

  def update_positions
    update_all_positions(params[:dataset_category].keys, params[:dataset_description])
    render :nothing => true
  end

  def edit_field_description_categories
    @field_description_categories = @dataset_description.field_description_categories
  end

  def update_field_description_categories
    if dataset_description.update_attributes(params[:dataset_description])
      redirect_to dataset_description, notice: 'success'
    else
      @field_description_categories = dataset_description.field_description_categories
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

  def dataset_description
    @dataset_description ||= DatasetDescription.find(params[:id])
  end

  def init_menu
    @submenu_partial = 'data_dictionary'
  end

  def params_with_category
    category = DatasetCategoryPreparer.prepare(
        params[:dataset_description].delete(:category),
        params[:dataset_description].delete(:category_id)
    )

    params[:dataset_description].merge(category_id: category.try(:id))
  end

  def new_or_detail_description_path
    if params[:commit] == I18n.t("global.save_and_create")
      new_dataset_description_path
    else
      dataset_description_path(@dataset_description)
    end
  end
end
