# -*- encoding : utf-8 -*-
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
  layout "frontend_public"

  def index
    @news = News.published.first
  end

  def locale
    target = (request.referer && !request.referer.empty?) ? request.referer : root_path
    I18n.locale = params[:locale] if params[:locale].present?
    redirect_to root_url(locale: I18n.locale == :sk ? nil : I18n.locale)
  end
end
