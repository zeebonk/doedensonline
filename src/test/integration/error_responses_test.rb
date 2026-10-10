require 'test_helper'

# Exceptions that map to a response status are rendered instead of raised
# (show_exceptions = :rescuable), as they are in production.
class ErrorResponsesTest < ActionDispatch::IntegrationTest
  def setup
    NewsComment.delete_all
    NewsItem.delete_all
    User.delete_all

    @admin = create_user!(
      first_name: 'Admin',
      last_name: 'McAdmin',
      email: 'admin@example.com',
      password: 'secret',
      notify_news: false,
      notify_photo_album: false,
      isadmin: true
    )

    sign_in_as @admin
  end

  # 400 Bad Request

  test "a scalar news_item param on news create returns 400" do
    assert_no_difference('NewsItem.count') do
      post '/news', params: { news_item: 'x' }
    end

    assert_response :bad_request
  end

  test "a scalar user param on settings update_profile returns 400" do
    patch '/settings/update_profile', params: { user: 'x' }

    assert_response :bad_request
    assert_equal 'Admin', @admin.reload.first_name
  end

  # 404 Not Found

  test "an unknown user id on the admin user page returns 404" do
    get "/users/#{User.maximum(:id) + 1}"

    assert_response :not_found
  end

  test "an unknown user id on the admin user edit page returns 404" do
    get "/users/#{User.maximum(:id) + 1}/edit"

    assert_response :not_found
  end

  test "an unknown route returns 404" do
    get '/does-not-exist'

    assert_response :not_found
  end
end
