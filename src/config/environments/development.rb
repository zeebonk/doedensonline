DoedensOnline::Application.configure do
  config.cache_classes = false
  config.whiny_nils = true

  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address              => ENV["DO_SMTP_HOST"],
    :port                 => 587,
    :user_name            => ENV["DO_SMTP_USERNAME"],
    :password             => ENV["DO_SMTP_PASSWORD"],
    :authentication       => :plain,
    :enable_starttls_auto => true,
    :domain               => 'doedensonline.nl',
  }
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { :host => 'dev.doedensonline.nl' }

  config.active_support.deprecation = :log
  config.action_dispatch.best_standards_support = :builtin

  config.log_level = :debug
end
