# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  before_filter :is_authorized
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'df582c3ae6fe8eb5445581a3e061317c'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  
  layout 'default'

private
  
  def is_authorized
    if request.path_parameters[:controller] == 'home'
      action = request.path_parameters[:action]
      return if action == 'sign_in'        || action == 'destroy_session'    || 
                action == 'authenticate'   || action == 'password_forgotten' ||
                action == 'reset_password'  
    end
    
    if !session[:user_id]
      redirect_to :controller => 'home', :action => 'sign_in'
    end
  end  
  
  def redirect_to_home_if_signed_in
    if session[:user_id]
      flash[:notice] = 'You are already signed in'
      redirect_to :controller => 'home', :action => 'index'
    end
  end 
  
  def current_user
    @current_user ||= User.find(session[:user_id])
  end
  
  
end
