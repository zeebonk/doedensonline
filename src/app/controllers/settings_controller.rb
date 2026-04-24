class SettingsController < ApplicationController
  # GET /settings
  def index
    redirect_to action: 'profile'
  end

  # GET /settings/profile
  def profile
    @user = current_user
  end

  # GET /settings/password
  def password
    @sub_page_title = t('page_titles.settings')
    @user = current_user
  end

  # GET /settings/notifications
  def notifications
    @sub_page_title = t('page_titles.settings')
    @user = current_user
  end

  # PUT /settings/update_profile
  def update_profile
    @user = current_user

    if @user.update_attributes(params[:user])
      flash[:settings] = t('flash.settings.profile_updated')
      redirect_to action: 'profile'
    else
      render action: "profile"
    end
  end

  # PUT /settings/update_notifications
  def update_notifications
    @user = current_user

    if @user.update_attributes(params[:user])
      flash[:settings] = t('flash.settings.notifications_updated')
      redirect_to action: 'notifications'
    else
      render action: "notifications"
    end
  end

  # PUT /settings/update_password
  def update_password
    @user = current_user
    # Try to authenticate the username and old password
    if User.authenticate(@user.first_name, params[:old_password])
      if params[:password].to_s.size < 3
        @user.errors.add(:base, t('flash.settings.password_too_short'))
      end
      if params[:password] != params[:password_confirmation]
        @user.errors.add(:base, t('flash.settings.password_mismatch'))
      end
      if @user.errors.empty? && @user.update_attribute(:password, params[:password])
        flash[:settings] = t('flash.settings.password_updated')
        redirect_to action: 'password'
      else
        render action: "password"
      end
    else
      # Authentication failed fo the old password
      @user.errors.add(:base, t('flash.settings.current_password_incorrect'))
      render action: "password"
    end
  end
end
