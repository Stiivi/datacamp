# -*- encoding : utf-8 -*-
# Records Controller
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

class RecordsController < ApplicationController
  include CommentsLoader
  
  before_filter :load_record
  
  privilege_required :edit_record, :only => [:edit, :update, :update_status]
  privilege_required :create_record, :only => [:new, :create]
  
  def show
    # Field descriptions
    if logged_in? && current_user.has_privilege?(:data_management)
      @field_descriptions = @dataset_description.field_descriptions
    else
      @field_descriptions = @dataset_description.visible_field_descriptions(:detail)
    end
    
    @related_records_and_fields = related_records_and_fields(@dataset_description, @record)
    
    load_comments
    
    @favorite = current_user.favorite_for!(@dataset_description, @record) if current_user
    
    respond_to do |wants|
      wants.html
      wants.xml { render :xml => @record }
    end
  end
  
  def new
    @form_url = dataset_records_path(@dataset_description)
  end
  
  def create
    record_params = params["kernel_ds_#{@dataset_description.identifier.singularize}".to_sym]
    @record.update_attributes(record_params)
    if @record.save
      redirect_to dataset_record_path(@dataset_description, @record)
    else
      render :action => "new"
    end
  end
  
  def edit
    @form_url = dataset_record_path(@dataset_description, @record)
  end
  
  def update
    record_params = params["kernel_ds_#{@dataset_description.identifier.singularize}".to_sym]

    @record.handling_user = current_user
    @record.update_attributes(record_params)
    
    if @record.save
      redirect_to dataset_record_path(@dataset_description, @record)
    else
      render :action => "edit"
    end
  end
  
  def update_status
    begin
      @record.record_status = params[:status]
      @record.save
    end if !params[:status].blank?
    redirect_to dataset_record_path(@dataset_description, @record)
  end
  
  def destroy
    @record.destroy
    redirect_to dataset_path(@dataset_description)
  end
  
  def fix
    @record.quality_status = nil
    @record.save
    @quality_status.find { |qs| qs.column_name == params[:field] }.destroy
  end
  
  protected
  def load_record
    @dataset_description = DatasetDescription.find_by_id!(params[:dataset_id])
    @dataset             = @dataset_description.dataset
    @dataset_class       = @dataset.dataset_record_class

    if params[:id]
      @record = @dataset_class.find_by_record_id! params[:id]
    else
      @record = @dataset_class.new
    end
    @quality_status = @record.quality_status_messages
  end
  
  def related_records_and_fields(dataset_description, record)
    @dataset_class.reflect_on_all_associations.delete_if{ |a| a.name =~ /^rel_/ }.map do |reflection|
      [ [record.send(reflection.name)].flatten.compact,
        DatasetDescription.find_by_identifier(reflection.name.to_s.gsub(Dataset::Base::prefix,'').pluralize).visible_fields_in_relation
      ]
    end
  end
end
