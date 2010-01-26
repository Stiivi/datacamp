# API Keys Controller
#
# Copyright:: (C) 2009 Knowerce, s.r.o.
# 
# Author:: Vojto Rinik <vojto@rinik.net>
# Date: Dec 2009
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

class ApiKeysController < ApplicationController
  def new
    if(has_privilege?(:manage_users) && params[:user_id])
      user = User.find_by_id(params[:user_id])
    else
      user = current_user
    end
    
    api_key = user.generate_api_key
    
    redirect_to (params[:user_id] ? edit_user_path(user) : account_path) + "#api"
  end
end