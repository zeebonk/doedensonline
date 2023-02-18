class SettingsController < ApplicationController

  # GET /settings
  def index
    redirect_to :action => 'profile'
  end
  
  # GET /settings/profile
  def profile
    @page_title = ["Instellingen"]
    @user = current_user
  end
  
  # GET /settings/password
  def password
    @page_title = ["Instellingen"]
    @sub_page_title = "Instellingen"
    @user = current_user
  end
  
  # GET /settings/notifications
  def notifications
    @page_title = ["Instellingen"]
    @sub_page_title = "Instellingen"
    @user = current_user
  end
  
  # POST /settings/update_profile
  def update_profile
    @user = current_user

    if @user.update_attributes(params[:user])
      flash[:settings] = 'Uw profiel is succesvol aangepast.'
      redirect_to :action => 'profile'
    else
      render :action => "profile"
    end
  end
  
  # POST /settings/update_profile
  def update_notifications
    @user = current_user

    if @user.update_attributes(params[:user])
      flash[:settings] = 'Uw notificatie instellingen zijn succesvol aangepast.'
      redirect_to :action => 'notifications'
    else
      render :action => "notifications"
    end
  end
  
  # POST /settings/update_password
  def update_password
    @user = current_user
    # Try to authenticate the username and old password
    if User.authenticate(@user.first_name, params[:old_password])
      if params[:password].to_s.size < 3
        @user.errors.add_to_base "Nieuw wachtwoord moet uit minimaal 3 tekens bestaan"
      end
      if params[:password] != params[:password_confirmation]
        @user.errors.add_to_base "Nieuw wachtwoord en confirmatie zijn niet aan elkaar gelijk"
      end
      if @user.errors.size == 0 && @user.update_attribute(:password, params[:password])
        flash[:settings] = 'Uw wachtwoord is succesvol gewijzigd.'
        redirect_to :action => 'password'
      else
        render :action => "password"            
      end
    else
      # Authentication failed fo the old password
      @user.errors.add_to_base "Huidig wachtwoord in incorrect"
      render :action => "password"      
    end
  end
end
