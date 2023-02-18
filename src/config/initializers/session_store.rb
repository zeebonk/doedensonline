# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_Doedens Online_session',
  :secret      => '245150889528a27449ee83fc2b0022aa51b669bcd5d360f9134fcfd0f46b6e8bfeb577e55ea70f0cd406cacb7e7d4145c740aa17b4ad4d0018982b92392e8ac9'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
