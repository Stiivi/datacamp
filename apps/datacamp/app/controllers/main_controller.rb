# Main Controller
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

class MainController < ApplicationController
  layout "frontend_main"
  
  before_filter :login_required, :except => [:index, :locale]
  
  def index
    @categories = DatasetCategory.find :all
    # @categories = descriptions.collect{|category, datasets|category ? t("global.other") : category}
    
    @popular = Access.find_popular_records
  end
  
  def locale
    target = (request.referer && !request.referer.empty?) ? request.referer : root_path
    if params[:locale]
      session[:locale] = params[:locale]
    end
    redirect_to target + params[:hash].to_s
  end
end
