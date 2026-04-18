require 'test_helper'

class HomeControllerTest < ActionController::TestCase

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries.clear
    # Fixtures store passwords as raw strings, but User#password= encrypts.
    # Start from a clean slate and create users through the model so
    # authentication actually works. NewsItem fixtures reference user_id: 1,
    # so clear them too to avoid orphaned associations when rendering index.
    NewsItem.delete_all
    User.delete_all
    @user = User.create!(
      :first_name  => 'Alice',
      :last_name   => 'Anderson',
      :email       => 'alice@example.com',
      :password    => 'secret',
      :notify_news => false,
      :isadmin     => false
    )
  end

  def sign_in_as(user)
    @request.session[:user_id] = user.id
  end

  # GET /home

  test "index redirects to sign_in when not signed in" do
    get :index
    assert_redirected_to :action => 'sign_in'
  end

  test "index renders when signed in" do
    sign_in_as @user
    get :index
    assert_response :success
    assert_equal ['Home'], assigns(:page_title)
    assert_not_nil assigns(:news_items)
  end

  # GET /home/sign_in

  test "sign_in is accessible without authentication" do
    get :sign_in
    assert_response :success
    assert_equal ['Inloggen'], assigns(:page_title)
  end

  test "sign_in redirects to index when already signed in" do
    sign_in_as @user
    get :sign_in
    assert_redirected_to :action => 'index'
  end

  # POST /home/authenticate

  test "authenticate signs in user with valid credentials" do
    post :authenticate, :first_name => 'Alice', :password => 'secret'
    assert_equal @user.id, session[:user_id]
    assert_redirected_to :action => 'index'
    assert_equal 'U bent succesvol ingelogd!', flash[:notice]
  end

  test "authenticate is case-insensitive for first_name" do
    post :authenticate, :first_name => 'alice', :password => 'secret'
    assert_equal @user.id, session[:user_id]
  end

  test "authenticate redirects back to stored request after login" do
    @request.session[:request] = '/news'
    post :authenticate, :first_name => 'Alice', :password => 'secret'
    assert_redirected_to '/news'
    assert_nil session[:request]
  end

  test "authenticate rejects wrong password" do
    post :authenticate, :first_name => 'Alice', :password => 'wrong'
    assert_nil session[:user_id]
    assert_redirected_to :action => 'sign_in'
    assert_equal 'U heeft een ongeldige voornaam/wachtwoord combinatie ingevuld!', flash[:error]
  end

  test "authenticate rejects unknown first_name" do
    post :authenticate, :first_name => 'Nobody', :password => 'secret'
    assert_nil session[:user_id]
    assert_redirected_to :action => 'sign_in'
  end

  # GET /home/sign_out

  test "sign_out redirects to sign_in when not signed in" do
    get :sign_out
    assert_redirected_to :action => 'sign_in'
  end

  test "sign_out renders when signed in" do
    sign_in_as @user
    get :sign_out
    assert_response :success
    assert_equal ['Uitloggen'], assigns(:page_title)
  end

  # POST /home/destroy_session

  test "destroy_session clears session when confirmed" do
    sign_in_as @user
    post :destroy_session, :commit => 'Ja, log mij uit!'
    assert_nil session[:user_id]
    assert_redirected_to :action => 'sign_in'
    assert_equal 'U bent succesvol uitgelogd!', flash[:notice]
  end

  test "destroy_session keeps session when not confirmed" do
    sign_in_as @user
    post :destroy_session, :commit => 'Cancel'
    assert_equal @user.id, session[:user_id]
    assert_redirected_to :action => 'index'
  end

  # GET /home/password_forgotten

  test "password_forgotten is accessible without authentication" do
    get :password_forgotten
    assert_response :success
    assert_equal ['Wachtwoord vergeten'], assigns(:page_title)
  end

  test "password_forgotten redirects to index when signed in" do
    sign_in_as @user
    get :password_forgotten
    assert_redirected_to :action => 'index'
  end

  # POST /home/reset_password

  test "reset_password resets password and sends email for matching user" do
    original_password = @user.password
    post :reset_password, :first_name => 'Alice', :email => 'alice@example.com'

    assert_redirected_to :action => 'sign_in'
    assert_not_equal original_password, @user.reload.password
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal ['alice@example.com'], ActionMailer::Base.deliveries.first.to
  end

  test "reset_password does nothing when no user matches" do
    original_password = @user.password
    post :reset_password, :first_name => 'Nobody', :email => 'nobody@example.com'

    assert_redirected_to :action => 'password_forgotten'
    assert_equal original_password, @user.reload.password
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

end
