# User Roles Controller
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

class UserRolesController < ApplicationController
  
  def index
    @user_roles = AccessRole.find :all
  end
  
  def new
    @user_role = AccessRole.new    
  end
  
  def create
    @user_role = AccessRole.new
    @user_role.update_attributes(params[:access_role])
    
    if @user_role.save
      redirect_to user_roles_path
    else
      render :action => "new"
    end
  end
  
  def edit
    @user_role = AccessRole.find_by_id params[:id]
  end
  
  def update
    @user_role = AccessRole.find_by_id params[:id]
    
    if @user_role.update_attributes(params[:access_role])
      redirect_to user_roles_path
    else
      render :action => "edit"
    end
  end
  
  def destroy
    @user_role = AccessRole.find_by_id params[:id]
    @user_role.destroy
    redirect_to user_roles_path
  end
end