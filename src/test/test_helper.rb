ENV["RAILS_ENV"] = "test"
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  fixtures :all

  def create_user!(attrs)
    User.create!(attrs)
  end
end

class ActionDispatch::IntegrationTest
  def sign_in_as(user, password = 'secret')
    post '/home/authenticate', first_name: user.first_name, password: password
  end
end
