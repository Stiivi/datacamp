# Users Controller
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

require 'csv'

class UsersController < ApplicationController
  before_filter :login_required, :except => [:restore]
  privilege_required :manage_users, :except => [:new, :restore]
  
  def index
    @filters = params[:filters] || {}
    active_filters = @filters.find_all do |field, value|
      %q{login name email api_access_level}.include?(field) &&
      value.present?
    end
    conditions_sql = active_filters.collect{|f,v|"#{f} LIKE ?"}.join(" AND ")
    conditions_values = active_filters.collect{|f,v|"%#{v}%"}
    
    respond_to do |wants|
      wants.html {
        paginate_options = {:page => params[:page]||1, :per_page => RECORDS_PER_PAGE}
        select_options = {:conditions => [conditions_sql, *conditions_values]}
        @users = User.paginate paginate_options.merge(select_options)
      }
      wants.csv {
        @users = User.find :all
        render :text => collection_as_csv(@users, [:login, :name, :email])
      }
    end
  end

  # render new.rhtml
  def new
    @user = User.new
  end
 
  def create
    @user = User.new(params[:user])
    success = @user && @user.save(false)
    if success
      redirect_to users_path
    else
      render :action => 'new'
    end
  end
  
  def destroy
    @user = User.find_by_id params[:id]
    @user.destroy
    redirect_to users_path
  end
  
  def edit
    @user = User.find_by_id params[:id]
  end
  
  def update
    @user = User.find_by_id params[:id]
    
    @user.attributes = params[:user]
    @user.access_right_ids = params[:user][:access_right_ids]
    @user.access_role_ids = params[:user][:access_role_ids]
    
    if @user.save(false)
      redirect_to edit_user_path(@user)
    else
      render :action => "edit"
    end
  end
  
  def restore
    @account = User.find_by_restoration_code!(params[:id] || ".")
    if request.method == :put
      user = params[:user]
      if user[:password] == user[:password_confirmation]
        @account.password = user[:password]
        @account.save(false)
        flash[:notice] = "Saved."
        redirect_to root_path
      else
        flash.now[:error] = "Password don't match."
      end
    end
  end
  
  def dashboard
    @user = current_user
  end
  
  def init_menu
    @submenu_partial = "settings"
  end
  
  protected
  
  # FIXME: Make this reusable
  def collection_as_csv(collection, fields)
    output = ""
    output << CSV.generate_line(fields)
    output << "\n"
    collection.each do |item|
      values = fields.collect do |field|
        item.send(field)
      end
      output << CSV.generate_line(values)
      output << "\n" unless item == collection.last
    end
    output
  end
end
