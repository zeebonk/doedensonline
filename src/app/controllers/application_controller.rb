class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  before_filter :is_authorized
  protect_from_forgery

  layout 'default'

private

  def root_src_img_tag(input)
    input = input.gsub('../../', '/')
    input = input.gsub('../', '/')
    return input
  end

  def create_images image
    image.create_large_image
    image.create_medium_image
    image.create_small_image
  end

  def remove_images filename
    FileUtils.remove_file "#{Rails.root}/public/images/small/#{filename}", true
    FileUtils.remove_file "#{Rails.root}/public/images/medium/#{filename}", true
    FileUtils.remove_file "#{Rails.root}/public/images/large/#{filename}", true
  end

  def is_authorized
    if controller_name == 'home'
      return if action_name == 'sign_in'        || action_name == 'destroy_session'    ||
                action_name == 'authenticate'   || action_name == 'password_forgotten' ||
                action_name == 'reset_password'
    end

    if !session[:user_id]
      session[:request] = request.fullpath
      redirect_to :controller => 'home', :action => 'sign_in'
    end
  end

  def redirect_to_home_if_signed_in
    if session[:user_id]
      flash[:notice] = 'You are already signed in'
      params[:request] = request.fullpath
      redirect_to :controller => 'home', :action => 'index'
    end
  end

  def current_user
    @current_user ||= User.find(session[:user_id])
  end

  def return_to_home_if_user_not_admin
    if !current_user.isadmin
      flash[:notice] = 'Only admins allowed there'
      redirect_to :controller => 'home', :action => 'index'
    end
  end

  def validate_author item
    if item.user != current_user
      flash[:error] = "U bent niet gemachtigd om opgegeven item te mogen wijzigen!"
      return redirect_to :action => 'index'
    end
  end

end
