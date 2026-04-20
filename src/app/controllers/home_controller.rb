class HomeController < ApplicationController

  before_filter :redirect_to_home_if_signed_in, :only => [:sign_in, :authenticate, :password_forgotten, :reset_password]

  # GET /home
  def index
    @page_title = [t('page_titles.home')]
    @news_items = NewsItem.latest(3,0)
  end

  # GET /home/sign_in
  def sign_in
    @page_title = [t('page_titles.sign_in')]
  end

  # POST /home/authenticate
  def authenticate
    @user = User.authenticate(params[:first_name], params[:password])
    if @user
      flash[:notice] = t('flash.home.signed_in')
      session[:user_id] = @user.id
      req = session[:request]
      session[:request] = nil
      if req
        redirect_to req
      else
        redirect_to :action => 'index'
      end
    else
      flash[:error] = t('flash.home.invalid_credentials')
      redirect_to :action => 'sign_in'
    end
  end

  # GET /home/sign_out
  def sign_out
    @page_title = [t('page_titles.sign_out')]
  end

  # POST /home/session_destroy
  def destroy_session
    if params[:commit] == t('home.sign_out.confirm')
      session[:user_id] = nil
      flash[:notice] = t('flash.home.signed_out')
      redirect_to :action => 'sign_in'
    else
      redirect_to :action => 'index'
    end
  end

  # GET /home/password_forgotten
  def password_forgotten
    @page_title = [t('page_titles.password_forgotten')]
  end

  # POST /home/reset_password
  def reset_password
    user = User.where('first_name = ? AND email = ?', params[:first_name], params[:email]).first
    if user
      user.generate_new_password
      flash[:notice] = t('flash.home.password_reset_sent')
      redirect_to :action => 'sign_in'
    else
      flash[:error] = t('flash.home.invalid_credentials')
      redirect_to :action => 'password_forgotten'
    end
  end

end
