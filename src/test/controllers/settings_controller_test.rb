require 'test_helper'

class SettingsControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Fixtures store passwords raw, but User#password= encrypts and
    # update_password authenticates against the encrypted form, so build
    # the user through the model.
    User.delete_all
    @user = create_user!(
      first_name: 'Alice',
      last_name: 'Anderson',
      email: 'alice@example.com',
      password: 'secret',
      notify_news: true,
      isadmin: false
    )
    sign_in_as @user
  end

  # Authorization

  test "redirects to sign_in when not signed in" do
    reset!
    get '/settings/profile', params: {}
    assert_redirected_to controller: 'home', action: 'sign_in'
  end

  # GET /settings

  test "index redirects to profile" do
    get '/settings', params: {}
    assert_redirected_to controller: 'settings', action: 'profile'
  end

  # GET /settings/profile

  test "profile renders with current user" do
    get '/settings/profile', params: {}
    assert_response :success
    assert_equal @user, assigns(:user)
  end

  # GET /settings/password

  test "password renders with current user" do
    get '/settings/password', params: {}
    assert_response :success
    assert_equal @user, assigns(:user)
  end

  # GET /settings/notifications

  test "notifications renders with current user" do
    get '/settings/notifications', params: {}
    assert_response :success
    assert_equal @user, assigns(:user)
  end

  # PATCH /settings/update_profile

  test "update_profile saves valid changes" do
    patch '/settings/update_profile', params: {
      user: { first_name: 'Alicia', last_name: 'Anderson', email: 'alicia@example.com' }
    }

    assert_redirected_to controller: 'settings', action: 'profile'
    assert_equal 'Uw profiel is succesvol aangepast.', flash[:settings]
    @user.reload
    assert_equal 'Alicia', @user.first_name
    assert_equal 'alicia@example.com', @user.email
  end

  test "update_profile re-renders profile on invalid input" do
    patch '/settings/update_profile', params: { user: { email: 'not-an-email' } }

    assert_response :success
    assert_template 'profile'
    assert assigns(:user).errors[:email].present?
    assert_not_equal 'not-an-email', @user.reload.email
  end

  # PATCH /settings/update_notifications

  test "update_notifications saves valid changes" do
    patch '/settings/update_notifications', params: { user: { notify_news: false } }

    assert_redirected_to controller: 'settings', action: 'notifications'
    assert_equal 'Uw notificatie instellingen zijn succesvol aangepast.', flash[:settings]
    assert_equal false, @user.reload.notify_news
  end

  test "update_notifications ignores params outside the notification scope" do
    original_email = @user.email
    patch '/settings/update_notifications', params: { user: { email: 'not-an-email' } }

    assert_redirected_to controller: 'settings', action: 'notifications'
    assert_equal original_email, @user.reload.email
  end

  # PATCH /settings/update_password

  test "update_password changes password with correct old password" do
    original_password = @user.password
    patch '/settings/update_password', params: {
      old_password: 'secret',
      password: 'newpass',
      password_confirmation: 'newpass'
    }

    assert_redirected_to controller: 'settings', action: 'password'
    assert_equal 'Uw wachtwoord is succesvol gewijzigd.', flash[:settings]
    assert_not_equal original_password, @user.reload.password
  end

  test "update_password rejects incorrect old password" do
    original_password = @user.password
    patch '/settings/update_password', params: {
      old_password: 'wrong',
      password: 'newpass',
      password_confirmation: 'newpass'
    }

    assert_response :success
    assert_template 'password'
    assert(assigns(:user).errors.full_messages.any? { |m| m =~ /Huidig wachtwoord/ })
    assert_equal original_password, @user.reload.password
  end

  test "update_password rejects too-short new password" do
    original_password = @user.password
    patch '/settings/update_password', params: {
      old_password: 'secret',
      password: 'ab',
      password_confirmation: 'ab'
    }

    assert_response :success
    assert_template 'password'
    assert(assigns(:user).errors.full_messages.any? { |m| m =~ /minimaal 3 tekens/ })
    assert_equal original_password, @user.reload.password
  end

  test "update_password rejects mismatched confirmation" do
    original_password = @user.password
    patch '/settings/update_password', params: {
      old_password: 'secret',
      password: 'newpass',
      password_confirmation: 'different'
    }

    assert_response :success
    assert_template 'password'
    assert(assigns(:user).errors.full_messages.any? { |m| m =~ /niet aan elkaar gelijk/ })
    assert_equal original_password, @user.reload.password
  end
end
