ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => ENV["DO_SMTP_HOST"],
  :port => 587,
  :user_name => ENV["DO_SMTP_USERNAME"],
  :password => ENV["DO_SMTP_PASSWORD"],
  :authentication => :plain,
  :enable_starttls_auto => true,
  :domain => 'doedensonline.nl',
}
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.default_charset = "utf-8"
