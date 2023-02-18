class Mailer < ActionMailer::Base


  # Sent a password forgottten email
  def password_forgotten(user, pass)
  	
	# Header information
    from       "DoedensOnline.nl <gijs@doedensonline.nl>"
    subject    "Nieuw wachtwoord"
    recipients user.email
    sent_on    Time.now
    
	# Template variables
    body[:user] = user
    body[:pass] = pass
    
  end
  
  
  # Sent a news news email
  def notify_new_news(target, news_item, current_user)
  	
  	# Header information
    from       "DoedensOnline.nl <gijs@doedensonline.nl>"
    subject    "Nieuw nieuwtje"
    recipients target
    sent_on    Time.now    
    
    # Template variables
    body[:news_item]    = news_item
    body[:current_user] = current_user    
    
  end

  
end
