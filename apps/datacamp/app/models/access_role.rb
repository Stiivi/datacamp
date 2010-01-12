class AccessRole < ActiveRecord::Base
  
  has_and_belongs_to_many :access_rights, :join_table => :access_role_rights
  has_and_belongs_to_many :users, :join_table => :user_access_rights
  
  def to_s
    title
  end
end