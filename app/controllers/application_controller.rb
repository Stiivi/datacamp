# Application Controller
#
# Copyright:: (C) 2009 Knowerce, s.r.o.
# 
# Author:: Vojto Rinik <vojto@rinik.net>
# Date: Aug 2009
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


# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
  attr_accessor :javascripts
  
  include AuthenticatedSystem
  include Datacamp::Logger
  
  # Session initialization
  before_filter :session_init
  before_filter :login_required
  before_filter :log
  before_filter :set_locale
  before_filter :load_pages
  before_filter :init_menu
  before_filter :set_mailer
  
  helper :all
  layout "frontend_main"
  
  protect_from_forgery

  def set_locale
    unless session[:locale].blank?
      I18n.locale = session[:locale].to_sym
    end
  end
  
  def session_init
    @current_session = Session.new_from_session(session, request)
  end

  def load_pages
    @pages = Page.find :all
  end

  def add_javascript what
    @javascripts ||= []
    @javascripts << what
  end
  
  private
  
  # Abstract
  def init_menu
  end
  
  def set_mailer
    ActionMailer::Base.default_url_options[:host] = request.host_with_port
  end
end
