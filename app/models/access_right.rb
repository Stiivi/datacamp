# -*- encoding : utf-8 -*-
class AccessRight < ActiveRecord::Base
  
  has_and_belongs_to_many :access_roles, :join_table => :access_role_rights
  has_and_belongs_to_many :users, :join_table => :user_access_rights
  
end
