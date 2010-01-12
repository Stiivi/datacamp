# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_data_dictionary_session',
  :secret      => '23064bc9571b15dd99f854a7306a6a522a5493b9a2935b3b046ac202e439ebbcb51ed843a2e120f223f6c385e697d9c313f812bf0ebcd1ebeff147a8f0994142'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
