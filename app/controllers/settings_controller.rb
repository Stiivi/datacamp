# -*- encoding : utf-8 -*-
# System Settings Controller
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

class SettingsController < ApplicationController
  privilege_required :edit_system_settings
  
  def index
    @settings = SystemVariable.all
  end
  
  def update_all
    settings = params[:settings]
    settings.each do |id, setting|
      system_var = SystemVariable.find_by_id(id.to_i)
      system_var.update_attributes(setting)
    end
    
    redirect_to settings_path
  end
  
  def init_menu
    @submenu_partial = "settings"
  end
end
