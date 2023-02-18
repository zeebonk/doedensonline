class HomeController < ApplicationController
  
  # GET /home
  def index
    @page_title = ["Home"]
    @news_items = NewsItem.latest(3,0)  
  end
  
  # GET /home/sign_in
  def sign_in
    @page_title = ["Inloggen"]
    redirect_to_home_if_signed_in
 
  end

  # POST /home/authenticate
  def authenticate
    redirect_to_home_if_signed_in
    @user = User.authenticate(params[:first_name], params[:password])
    if @user
      flash[:notice] = 'U bent succesvol ingelogd!'
      session[:user_id] = @user.id
      req = session[:request]
      session[:request] = nil
      if req
        redirect_to req
      else
        redirect_to :action => 'index'
      end
    else
      flash[:error] = 'U heeft een ongeldige voornaam/wachtwoord combinatie ingevuld!'
      redirect_to :action => 'sign_in'
    end
  end
  
  # GET /home/sign_out
  def sign_out
    @page_title = ["Uitloggen"]
  end
  
  # POST /home/session_destroy
  def destroy_session
    if params[:commit] == 'Ja, log mij uit!'
      session[:user_id] = nil
      flash[:notice] = 'U bent succesvol uitgelogd!'
      redirect_to :action => 'sign_in'
    else
      redirect_to :action => 'index'
    end
  end
  
  # GET /home/password_forgotten
  def password_forgotten
    @page_title = ["Wachtwoord vergeten"]
    redirect_to_home_if_signed_in
  end
  
  # POST /home/reset_password
  def reset_password
    redirect_to_home_if_signed_in
    user = User.find(:first, :conditions => ['first_name = ? AND email = ?', params[:first_name], params[:email]] )
    if user
      user.generate_new_password
      flash[:notice] = 'Een nieuw wachtwoord is naar het opgegeven emailadres verstuurd.'
      return redirect_to :action => 'sign_in'
    else
      flash[:error] = 'U heeft een ongeldige voornaam/wachtwoord combinatie ingevuld!'
      return redirect_to :action => 'password_forgotten'
    end        
  end
  
end