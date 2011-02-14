# -*- encoding : utf-8 -*-
require 'digest/sha1'

class User < ActiveRecord::Base

  include Api::Accessable

  has_and_belongs_to_many :access_rights, :join_table => :user_access_rights
  has_and_belongs_to_many :access_roles, :join_table => :user_access_roles

  has_many :comments
  has_many :favorites
  
  has_many :sessions
  has_many :api_keys
  
  has_many :changes
  
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message
  
  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100
  
  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  attr_accessible :login, :email, :name, :password, :password_confirmation, :user_role_id, :loc, :about, :records_per_page, :is_super_user, :api_access_level, :accepts_terms

  # Callbacks
  after_create :generate_api_key
  
  # Acceptance of terms
  attr_accessor :accepts_terms
  validates_presence_of :accepts_terms
  validates_acceptance_of :accepts_terms
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login.downcase) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end
  
  
  #############################################################################
  # Checks if user has a privilige
  # FIXME: Use SQL-based detection

  def has_right?(right)
    # Super-user has all the rights
    return true if is_super_user

    # Check for particular rights
    @access_rights ||= self.access_rights.collect(&:identifier)
    return true if @access_rights.include?(right.to_s)

    # Check for rights in roles
    @rights_from_roles ||= (self.access_roles.collect do |role|
      role.access_rights.collect(&:identifier)
    end).flatten
    return true if @rights_from_roles.include?(right.to_s)

    return false
  end
  
  def has_one_of_rights?(*list_of_rights)
    list_of_rights.each do |right|
      return true if has_right?(right)
    end
    return false
  end
  
  # FIXME: Deprecated
  def has_privilege?(priv)
    return has_right?(priv)
  end
  
  def to_s
    name.empty? ? login : name    
  end
  
  #############################################################################
  # Reload score
  def reload_score
    # FIXME: Score counting algoritmus :)
    self.class.find(:first, :select => "sum(comments.score)", :from => "comments", :conditions => {"comments.user_id" => self.id})
    
    save
  end

  #############################################################################
  # Check for favorite
  
  def has_favorite?(dataset_description, record = nil)
    favorite_for(dataset_description, record) ? true : false
  end
  
  # Favorite for finds favorite
  def favorite_for(dataset_description, record = nil)
    conditions = {}
    conditions[:dataset_description_id] = dataset_description.id
    if record
      conditions[:record_id] = record.id
    else
      conditions[:record_id] = nil
    end
    self.favorites.find(:first, :conditions => conditions)
  end
  
  # Bang version finds favorite or create a new one
  def favorite_for!(dataset_description, record = nil)
    favorite = favorite_for(dataset_description, record)
    favorite ||= Favorite.new(:user => self, 
                              :dataset_description => dataset_description, 
                              :record_id => (record ? record.id : nil)
                             )
    favorite
  end
  
  #############################################################################
  # Restoration
  
  def create_restoration_code
    self.restoration_code = Digest::SHA1.hexdigest(self.login + Time.now.to_s);
  end
  
  #############################################################################
  # Records per page
  
  def records_per_page
    super || RECORDS_PER_PAGE
  end
  
  #############################################################################
  # API Key
  
  def api_key
    api_keys.find(:first, :conditions => {:is_valid => true})
  end
  
  def generate_api_key
    # Deactivate existing keys
    self.api_keys.each do |api_key|
      api_key.is_valid = false
      api_key.save
    end
    
    # Create a new one
    api_key = self.api_keys.build({:is_valid => true})
    api_key.init_random_key
    api_key.save
    
    api_key
  end

end
