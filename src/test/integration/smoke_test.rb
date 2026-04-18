require 'test_helper'

# Placeholder: rake's `test:integration` task fails on an empty glob, so one
# file must exist even though there are no real integration tests yet.
class SmokeTest < ActionController::IntegrationTest
  test "placeholder" do
    assert true
  end
end
