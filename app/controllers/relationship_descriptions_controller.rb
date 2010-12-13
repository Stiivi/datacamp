# -*- encoding : utf-8 -*-
# Relationship Descriptions Controller
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

# FIXME: unused, remove this file

class RelationshipDescriptionsController < ApplicationController
  before_filter :get_dataset_description
  protect_from_forgery :except => 'order'
  
  def index
    raise @dataset_description.to_yaml
  end
  
  def new
    @relationship_description = @dataset_description.relationship_descriptions.build
    
    respond_to do |wants|
      wants.html
      wants.js
    end
  end
  
  def create
    @relationship_description = @dataset_description.relationship_descriptions.build(params[:relationship_description])
    
    saved = @relationship_description.save
    respond_to do |wants|
      wants.html do
        if saved
          redirect_to @relationship_description.dataset_description
        else
          render :action => 'new'
        end
      end
      wants.js
    end
  end
  
  def destroy
    @relationship_description = RelationshipDescription.find_by_id(params[:id])
    @relationship_description.destroy
    redirect_to @dataset_description
  end
  
  def edit
    @relationship_description = RelationshipDescription.find_by_id(params[:id])
    
    respond_to do |wants|
      wants.html
      wants.js
    end
  end
  
  # PUT /dataset_descriptions/1/attributes/1
  def update
    @relationship_description = RelationshipDescription.find_by_id(params[:id])
    
    respond_to do |format|
      if @relationship_description.update_attributes(params[:relationship_description])
        flash[:notice] = 'DatasetDescription was successfully updated.'
        format.html { redirect_to(@dataset_description) }
        format.xml  { head :ok }
        format.js
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @dataset_description.errors, :status => :unprocessable_dataset_description }
        format.js
      end
    end
  end
  
  # POST /dataset_descriptions/1/attributes/order
  # Saves order
  def order
    weight = 1
    ids = params[:order].split(',')
    ids.each do |id|
      begin
        ea = RelationshipDescription.find(id)
        ea.weight = weight
        ea.save
        weight += 1
      rescue
        next
      end
    end
    render :nothing => true
  end
  
  protected
  
  def get_dataset_description
    @dataset_description = DatasetDescription.find_by_slug!(params[:dataset_description_id])
  end
end
