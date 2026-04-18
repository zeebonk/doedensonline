require 'test_helper'

class UsersControllerTest < ActionController::TestCase

  def setup
    @admin = users(:admin)
    @user = users(:one)
    sign_in_as @admin
  end

  def sign_in_as(user)
    @request.session[:user_id] = user.id
  end

  def valid_user_attributes(overrides = {})
    {
      :first_name  => 'Charlie',
      :last_name   => 'Chaplin',
      :email       => 'charlie@example.com',
      :password    => 'secret',
      :notify_news => false
    }.merge(overrides)
  end

  # Authorization

  test "redirects to home when no user is signed in" do
    @request.session[:user_id] = nil
    get :index
    assert_redirected_to :controller => 'home', :action => 'sign_in'
  end

  test "redirects to home when signed in user is not an admin" do
    sign_in_as users(:one)
    get :index
    assert_redirected_to :controller => 'home', :action => 'index'
    assert_equal 'Only admins allowed there', flash[:notice]
  end

  # GET /users

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
    assert assigns(:users).include?(@user)
  end

  test "sets the page title on index" do
    get :index
    assert_equal ['Users'], assigns(:page_title)
  end

  # GET /users/:id

  test "should show user" do
    get :show, :id => @user.id
    assert_response :success
    assert_equal @user, assigns(:user)
  end

  # GET /users/new

  test "should get new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:user)
    assert assigns(:user).new_record?
  end

  # POST /users

  test "should create user with valid attributes" do
    assert_difference('User.count', 1) do
      post :create, :user => valid_user_attributes
    end

    assert_redirected_to user_path(assigns(:user))
    assert_equal 'User was successfully created.', flash[:notice]
  end

  test "does not create user with invalid attributes and re-renders new" do
    assert_no_difference('User.count') do
      post :create, :user => valid_user_attributes(:email => 'not-an-email')
    end

    assert_response :success
    assert_template 'new'
    assert assigns(:user).errors.on(:email)
  end

  test "does not create user with blank password" do
    assert_no_difference('User.count') do
      post :create, :user => valid_user_attributes(:password => '')
    end

    assert_response :success
    assert_template 'new'
  end

  # GET /users/:id/edit

  test "should get edit" do
    get :edit, :id => @user.id
    assert_response :success
    assert_equal @user, assigns(:user)
  end

  # PUT /users/:id

  test "should update user with valid attributes" do
    put :update, :id => @user.id, :user => { :first_name => 'Updated' }

    assert_redirected_to user_path(assigns(:user))
    assert_equal 'User was successfully updated.', flash[:notice]
    assert_equal 'Updated', @user.reload.first_name
  end

  test "does not update user with invalid attributes and re-renders edit" do
    put :update, :id => @user.id, :user => { :email => 'not-an-email' }

    assert_response :success
    assert_template 'edit'
    assert_not_equal 'not-an-email', @user.reload.email
  end

  # DELETE /users/:id

  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete :destroy, :id => @user.id
    end

    assert_redirected_to users_path
    assert_raise(ActiveRecord::RecordNotFound) { User.find(@user.id) }
  end

end
