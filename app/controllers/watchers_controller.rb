# Watchers Controller
#
# Manage people interested in being notified about the application
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

class WatchersController < ApplicationController
  before_filter :login_required, :except => [:new, :create]
  privilege_required :user_management, :except => [:new, :create]
  
  # GET /watchers
  # GET /watchers.xml
  def index
    @watchers = Watcher.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @watchers }
    end
  end

  # GET /watchers/1
  # GET /watchers/1.xml
  def show
    @watcher = Watcher.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @watcher }
    end
  end

  # GET /watchers/new
  # GET /watchers/new.xml
  def new
    @watcher = Watcher.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @watcher }
    end
  end

  # GET /watchers/1/edit
  def edit
    @watcher = Watcher.find(params[:id])
  end

  # POST /watchers
  # POST /watchers.xml
  def create
    @watcher = Watcher.new(params[:watcher])

    respond_to do |format|
      if @watcher.save
        flash[:notice] = t("watchers.success")
        format.html { redirect_to(root_path) }
        format.xml  { render :xml => @watcher, :status => :created, :location => @watcher }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @watcher.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /watchers/1
  # PUT /watchers/1.xml
  def update
    @watcher = Watcher.find(params[:id])

    respond_to do |format|
      if @watcher.update_attributes(params[:watchers])
        flash[:notice] = 'Watcher was successfully updated.'
        format.html { redirect_to(@watcher) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @watcher.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /watchers/1
  # DELETE /watchers/1.xml
  def destroy
    @watcher = Watcher.find(params[:id])
    @watcher.destroy

    respond_to do |format|
      format.html { redirect_to(watchers_url) }
      format.xml  { head :ok }
    end
  end
end
