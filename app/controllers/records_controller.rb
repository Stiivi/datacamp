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
  
  privilege_required :edit_record, :only => [:edit, :update, :update_status,:delete_relationship,:add_relationship]
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
    @related_records_and_fields = related_records_and_fields(@dataset_description, @record)
  end
  
  def update
    record_params = params["kernel_ds_#{@dataset_description.identifier.singularize}".to_sym]

    @record.handling_user = current_user
    saved = @record.update_attributes(record_params)
    
    if saved
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
  
  def delete_relationship
    dataset_description = DatasetDescription.find(params[:dataset_id])
    record = dataset_description.dataset.dataset_record_class.find_by_record_id(params[:id])
    if params[:macro] == 'has_many'
      related_dataset_description = DatasetDescription.find(params[:related_dataset])
      related_record = related_dataset_description.dataset.dataset_record_class.find_by_record_id(params[:related_id])
      
      record.send(params[:reflection]).delete(related_record) rescue related_record.send("ds_#{dataset_description.identifier.singularize}=", nil)
      deleted = related_record.save
    else
      record.send("#{params[:reflection]}=", nil)
      deleted = record.save
    end
    
    notice = deleted ? t('relation.deleted') : t('relation.delete_failed')
    redirect_to dataset_record_path(dataset_description, record), notice: notice
  end
  
  def add_relationship
    dataset_description = DatasetDescription.find(params[:dataset_id])
    record = dataset_description.dataset.dataset_record_class.find(params[:id])
    related_dataset_class = DatasetDescription.find(params[:related_dataset]).dataset.dataset_record_class
    related_record = related_dataset_class.find_by_record_id(params[:related_id])
    
    added = record.send(params[:reflection]) << related_record if related_record.present?
    notice = added ? t('relation.added') : t('relation.add_failed')
    redirect_to dataset_record_path(dataset_description, record), notice: notice
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
    @dataset_class.reflect_on_all_associations.delete_if{ |a| a.name =~ /^dc_/ }.map do |reflection|
      dd = DatasetDescription.find_by_identifier(reflection.name.to_s.gsub(/#{Dataset::Base::prefix}|_morphed/,'').pluralize)
      [ [record.send(reflection.name)].flatten.compact,
        dd.visible_fields_in_relation,
        reflection.name,
        dd,
        reflection.macro
      ] if dd.present?
    end
  end
end
