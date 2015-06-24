# -*- encoding : utf-8 -*-
class Session < ActiveRecord::Base
  belongs_to :user
  has_many :searches
  
  cattr_accessor :current_session

  def self.new_from_session(session, request)
    begin
      self.current_session = self.find_or_create_by_session_id(session[:session_id])
    rescue
      begin
        self.current_session = self.create(session_id: session[:session_id])
      end
    end

    return unless self.current_session

    if session[:user_id] && !current_session.user_id && session[:user_id] != current_session.user_id
      current_session.user_id = session[:user_id]
      current_session.save
    end

    if current_session.remote_ip != request.remote_ip
      current_session.remote_ip = request.remote_ip
      current_session.save
    end
    current_session
  end
end
