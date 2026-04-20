class Mailer < ActionMailer::Base

  default :from => "DoedensOnline.nl <gijs@doedensonline.nl>"

  # Sent a password forgottten email
  def password_forgotten(user, pass)
    @user = user
    @pass = pass
    mail(:to => user.email, :subject => "Nieuw wachtwoord")
  end

  # Sent a news news email
  def notify_new_news(target, news_item, current_user)
    @news_item    = news_item
    @current_user = current_user
    mail(:to => target, :subject => "Nieuw nieuwtje")
  end

end
