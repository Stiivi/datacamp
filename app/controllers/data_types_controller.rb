# -*- encoding : utf-8 -*-
# Data Types Controller
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

class DataTypesController < ApplicationController
  # GET /data_types
  # GET /data_types.xml
  def index
    @data_types = DataType.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @data_types }
      format.json { render :json => @data_types.to_json(:methods => :operators) }
    end
  end

  # GET /data_types/new
  # GET /data_types/new.xml
  def new
    @data_type = DataType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @data_type }
    end
  end

  # GET /data_types/1/edit
  def edit
    @data_type = DataType.find(params[:id])
  end

  # POST /data_types
  # POST /data_types.xml
  def create
    @data_type = DataType.new(params[:data_type])

    respond_to do |format|
      if @data_type.save
        flash[:notice] = 'DataType was successfully created.'
        format.html { redirect_to(data_types_url) }
        format.xml  { render :xml => @data_type, :status => :created, :location => @data_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @data_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /data_types/1
  # PUT /data_types/1.xml
  def update
    @data_type = DataType.find(params[:id])

    respond_to do |format|
      if @data_type.update_attributes(params[:data_type])
        flash[:notice] = 'DataType was successfully updated.'
        format.html { redirect_to(data_types_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @data_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /data_types/1
  # DELETE /data_types/1.xml
  def destroy
    @data_type = DataType.find(params[:id])
    @data_type.destroy

    respond_to do |format|
      format.html { redirect_to(data_types_url) }
      format.xml  { head :ok }
    end
  end
end
