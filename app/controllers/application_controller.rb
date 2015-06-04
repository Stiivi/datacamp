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

  before_filter :init_search_object
  def init_search_object
    if params[:search_id].present?
      @search_predicates = Search.find_by_id(params[:search_id]).query.predicates
    elsif params[:controller] == 'searches' && params[:id].present?
      search = Search.find_by_id(params[:id])
      if search
        @search_predicates = search.query.predicates
      else
        redirect_to root_path
      end
    end
  end

  helper :all
  layout "frontend_main"

  def default_url_options(options={})
    logger.debug "default_url_options is passed options: #{options.inspect}\n"
    { locale: I18n.locale != :sk ? I18n.locale : nil }
  end

  def set_locale
    # FIXME: we should use I18n.default_locale, don't we?
    I18n.locale = params[:locale] || :sk
   end

  def session_init
    @current_session = Session.new_from_session(session, request)
  end

  def load_pages
    @pages = Page.includes(:translations).all
  end

  def add_javascript what
    @javascripts ||= []
    @javascripts << what
  end

  rescue_from 'ActiveRecord::RecordNotFound' do |exception|
    render 'pages/datanest_404', status: 404
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
  
  before_filter :set_request_environment
private
  # stores parameters for current request
  def set_request_environment
    User.current = current_user # current_user is set by restful_authentication
    # You would also set the time zone for Rails time zone support here:
    # Time.zone = Person.current.time_zone
  end

  def index_page
    @__index_page ||= Page.find_by_page_name("index")
  end

  protected

  def update_all_positions(model, ids)
    items = model.all
    items.each do |item|
      new_index = ids.index(item.id.to_s)
      item.update_attribute(:position, new_index+1) if new_index
    end
  end
end
