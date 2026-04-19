require 'test_helper'

# Rails 2.3's `default_helper_module!` rescues MissingSourceFile, but Ruby 1.9
# raises a plain LoadError when a helper file is missing — the message format
# changed, so ActiveSupport's wrapper no longer promotes it.
ActionController::Base.class_eval do
  class << self
    def default_helper_module_with_loaderror_rescue!
      default_helper_module_without_loaderror_rescue!
    rescue LoadError
    end
    alias_method_chain :default_helper_module!, :loaderror_rescue
  end
end

# Dummy controller that exposes ApplicationController's filters and private
# helpers through trivial actions so they can be exercised in isolation.
class ApplicationControllerTestSubjectController < ApplicationController
  def index
    render :text => 'index ok'
  end

  def current_user_name
    render :text => current_user.first_name
  end

  def admin_only
    return_to_home_if_user_not_admin
    render :text => 'admin ok' unless performed?
  end

  def home_if_signed_in
    redirect_to_home_if_signed_in
    render :text => 'not signed in' unless performed?
  end

  def author_only
    item = NewsItem.find(params[:id])
    validate_author(item)
    render :text => 'author ok' unless performed?
  end

  def echo_msg
    render :text => "#{params[:msg].encoding.name}:#{params[:msg]}"
  end

  def image_path
    render :text => root_src_img_tag(params[:input])
  end
end

class ApplicationControllerTest < ActionController::TestCase
  tests ApplicationControllerTestSubjectController

  def setup
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
    @admin = User.create!(
      :first_name  => 'Admin',
      :last_name   => 'User',
      :email       => 'admin@example.com',
      :password    => 'secret',
      :notify_news => false,
      :isadmin     => true
    )
  end

  def sign_in_as(user)
    @request.session[:user_id] = user.id
  end

  # is_authorized

  test "is_authorized redirects unauthenticated request to sign_in" do
    get :index
    assert_redirected_to :controller => 'home', :action => 'sign_in'
  end

  test "is_authorized stores the original request path in the session" do
    get :index
    assert_not_nil @request.session[:request]
  end

  test "is_authorized passes through when signed in" do
    sign_in_as @user
    get :index
    assert_response :success
    assert_equal 'index ok', @response.body
  end

  # current_user

  test "current_user returns the user matching session[:user_id]" do
    sign_in_as @user
    get :current_user_name
    assert_response :success
    assert_equal 'Alice', @response.body
  end

  # return_to_home_if_user_not_admin

  test "return_to_home_if_user_not_admin lets admins through" do
    sign_in_as @admin
    get :admin_only
    assert_response :success
    assert_equal 'admin ok', @response.body
  end

  test "return_to_home_if_user_not_admin redirects non-admins to home index" do
    sign_in_as @user
    get :admin_only
    assert_redirected_to :controller => 'home', :action => 'index'
    assert_equal 'Only admins allowed there', flash[:notice]
  end

  # redirect_to_home_if_signed_in

  test "redirect_to_home_if_signed_in redirects signed-in users to home index" do
    sign_in_as @user
    get :home_if_signed_in
    assert_redirected_to :controller => 'home', :action => 'index'
    assert_equal 'You are already signed in', flash[:notice]
  end

  # validate_author

  test "validate_author lets the author continue" do
    sign_in_as @user
    news_item = NewsItem.create!(:message => 'hi', :user_id => @user.id)

    get :author_only, :id => news_item.id

    assert_response :success
    assert_equal 'author ok', @response.body
  end

  test "validate_author redirects non-author with an error flash" do
    sign_in_as @user
    news_item = NewsItem.create!(:message => 'hi', :user_id => @admin.id)

    get :author_only, :id => news_item.id

    assert_redirected_to :controller => 'application_controller_test_subject', :action => 'index'
    assert_equal 'U bent niet gemachtigd om opgegeven item te mogen wijzigen!', flash[:error]
  end

  # force_utf8_params

  test "force_utf8_params re-encodes string params to UTF-8" do
    sign_in_as @user
    get :echo_msg, :msg => 'hello'
    assert_response :success
    assert_equal 'UTF-8:hello', @response.body
  end

  # root_src_img_tag

  test "root_src_img_tag rewrites ../../ prefix to /" do
    sign_in_as @user
    get :image_path, :input => '../../images/foo.png'
    assert_equal '/images/foo.png', @response.body
  end

  test "root_src_img_tag rewrites ../ prefix to /" do
    sign_in_as @user
    get :image_path, :input => '../images/foo.png'
    assert_equal '/images/foo.png', @response.body
  end
end
