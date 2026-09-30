require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Fixtures store passwords as raw strings, but User#password= encrypts.
    # Build users through the model so the real sign-in flow works.
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
    @user = create_user!(
      first_name: 'Alice',
      last_name: 'Anderson',
      email: 'alice@example.com',
      password: 'secret',
      notify_news: false,
      notify_photo_album: false,
      isadmin: false
    )
    sign_in_as @admin
  end

  def valid_user_attributes(overrides = {})
    {
      first_name: 'Charlie',
      last_name: 'Chaplin',
      email: 'charlie@example.com',
      password: 'secret',
      notify_news: false
    }.merge(overrides)
  end

  # Authorization

  test "redirects to home when no user is signed in" do
    reset!
    get '/users', params: {}
    assert_redirected_to controller: 'home', action: 'sign_in'
  end

  test "redirects to home when signed in user is not an admin" do
    reset!
    sign_in_as @user
    get '/users', params: {}
    assert_redirected_to controller: 'home', action: 'index'
    assert_equal 'Only admins allowed there', flash[:notice]
  end

  # GET /users

  test "should get index" do
    get '/users', params: {}
    assert_response :success
    assert_not_nil assigns(:users)
    assert assigns(:users).include?(@user)
  end

  # GET /users/:id

  test "should show user" do
    get "/users/#{@user.id}", params: {}
    assert_response :success
    assert_equal @user, assigns(:user)
  end

  # GET /users/new

  test "should get new" do
    get '/users/new', params: {}
    assert_response :success
    assert_not_nil assigns(:user)
    assert assigns(:user).new_record?
  end

  # POST /users

  test "should create user with valid attributes" do
    assert_difference('User.count', 1) do
      post '/users', params: { user: valid_user_attributes }
    end

    assert_redirected_to user_path(assigns(:user))
    assert_equal I18n.t('flash.users.created'), flash[:notice]
  end

  test "does not create user with invalid attributes and re-renders new" do
    assert_no_difference('User.count') do
      post '/users', params: { user: valid_user_attributes(email: 'not-an-email') }
    end

    assert_response :success
    assert_template 'new'
    assert assigns(:user).errors[:email].present?
  end

  test "does not create user with blank password" do
    assert_no_difference('User.count') do
      post '/users', params: { user: valid_user_attributes(password: '') }
    end

    assert_response :success
    assert_template 'new'
  end

  # GET /users/:id/edit

  test "should get edit" do
    get "/users/#{@user.id}/edit", params: {}
    assert_response :success
    assert_equal @user, assigns(:user)
  end

  # PATCH /users/:id

  test "should update user with valid attributes" do
    patch "/users/#{@user.id}", params: { user: { first_name: 'Updated' } }

    assert_redirected_to user_path(assigns(:user))
    assert_equal I18n.t('flash.users.updated'), flash[:notice]
    assert_equal 'Updated', @user.reload.first_name
  end

  test "does not update user with invalid attributes and re-renders edit" do
    patch "/users/#{@user.id}", params: { user: { email: 'not-an-email' } }

    assert_response :success
    assert_template 'edit'
    assert_not_equal 'not-an-email', @user.reload.email
  end

  # DELETE /users/:id

  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete "/users/#{@user.id}", params: {}
    end

    assert_redirected_to users_path
    assert_raise(ActiveRecord::RecordNotFound) { User.find(@user.id) }
  end
end
