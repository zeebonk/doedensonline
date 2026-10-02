class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  before_action :is_authorized
  protect_from_forgery prepend: true

  layout 'default'

  private

  def root_src_img_tag(input)
    input = input.gsub('../../', '/')
    input.gsub('../', '/')
  end

  def create_images(image)
    image.create_large_image
    image.create_medium_image
    image.create_small_image
  end

  def remove_images(filename)
    FileUtils.remove_file "#{Rails.root}/public/images/small/#{filename}", true
    FileUtils.remove_file "#{Rails.root}/public/images/medium/#{filename}", true
    FileUtils.remove_file "#{Rails.root}/public/images/large/#{filename}", true
  end

  def is_authorized
    return if controller_name == 'home' && %w[sign_in destroy_session authenticate password_forgotten reset_password].include?(action_name)

    unless session[:user_id]
      session[:request] = request.fullpath
      redirect_to controller: 'home', action: 'sign_in'
    end
  end

  def redirect_to_home_if_signed_in
    if session[:user_id]
      flash[:notice] = t('flash.application.already_signed_in')
      params[:request] = request.fullpath
      redirect_to controller: 'home', action: 'index'
    end
  end

  def current_user
    @current_user ||= User.find(session[:user_id])
  end

  def return_to_home_if_user_not_admin
    unless current_user.isadmin
      flash[:notice] = t('flash.application.admins_only')
      redirect_to controller: 'home', action: 'index'
    end
  end

  def user_is_author(item)
    if item.user != current_user
      flash[:error] = t('flash.application.not_authorized')
      redirect_to action: 'index'
      return false
    end
    true
  end
end
