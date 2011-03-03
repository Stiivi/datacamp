# -*- encoding : utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery
  
  # directly copied over from rails 2 application_controller
  attr_accessor :javascripts

  include AuthenticatedSystem
  include CaptchaHelper
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

  def set_locale
    if session[:locale].blank?
      I18n.locale = :sk
    else
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
  
  def delayed_job_admin_authentication
    has_privilege? :delayed_job_admin
  end
end
