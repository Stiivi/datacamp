# -*- encoding : utf-8 -*-
module Datacamp::Logger
  def log
    access = Access.new
    access.session = @current_session
    access.params = params.to_yaml
    access.controller = params[:controller]
    access.action = params[:action]
    access.url = request.url
    access.referrer = request.referrer
    access.http_method = request.method.to_s
    # FIXME this is not a good way to do this. Although it might suffice for now. 
    # we need to log those dataset and record ids for statistics - which will probably
    # have their own table & log in future.
    if params[:controller] == "records" && params[:action] == "show" && params[:dataset_id] && params[:id]
      # We're dealing with record request
      access.dataset_description_id = params[:dataset_id]
      access.record_id = params[:id]
    end
    if params[:controller] == "datasets" && params[:action] == "show" && params[:id]
      # We're dealing with dataset request
      access.dataset_description_id = params[:id]
    end
    access.save
  end
end
