require 'test_helper'

class HealthCheckTest < ActionDispatch::IntegrationTest
  test "up returns 200 without requiring sign in" do
    get '/up'

    assert_response :success
  end
end
