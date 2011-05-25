# -*- encoding : utf-8 -*-
# Dataset Categories Controller
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

class DatasetCategoriesController < ApplicationController
  before_filter :login_required
  privilege_required :edit_dataset_description
  
  def index
    @categories = DatasetCategory.all
    respond_to do |wants|
      wants.html
      wants.xml { render :xml => @categories.to_xml(:methods => [:title, :description], :root => "category") }
    end
  end
  
  def new
    flash[:return_url] = request.referer
    @category = DatasetCategory.new
    
    respond_to do |wants|
      wants.html
      wants.js
    end
  end
  
  def create
    @category = DatasetCategory.new
    if @category.update_attributes(params[:dataset_category])
      redirect_to flash[:return_url] || dataset_descriptions_path
    else
      render :action => "new"
    end
  end
  
  def edit
    @category = DatasetCategory.find_by_id!(params[:id])
    
    respond_to do |wants|
      wants.html
      wants.js
    end
  end
  
  def update
    @category = DatasetCategory.find_by_id!(params[:id])
    @category.update_attributes(params[:dataset_category])
    
    respond_to do |wants|
      wants.js { render :nothing => true }
      wants.html { redirect_to categories_path }
    end
  end
  
  def destroy
    @category = DatasetCategory.find_by_id!(params[:id])
    @category.destroy
    
    respond_to do |wants|
      wants.html { redirect_to params[:return_to_category_index] ? dataset_categories_path : dataset_descriptions_path }
    end
  end
  
  protected
  def init_menu
    @submenu_partial = "data_dictionary"
  end
end
