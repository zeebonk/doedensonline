DoedensOnline::Application.configure do
  config.cache_classes = false

  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.assets.compress = false
  config.assets.debug = true

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV["DO_SMTP_HOST"],
    port: 587,
    user_name: ENV["DO_SMTP_USERNAME"],
    password: ENV["DO_SMTP_PASSWORD"],
    authentication: :plain,
    enable_starttls_auto: true,
    domain: 'doedensonline.nl'
  }
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: 'dev.doedensonline.nl' }

  config.active_support.deprecation = :log

  config.active_record.mass_assignment_sanitizer = :strict
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  config.log_level = :debug

  I18n.exception_handler = lambda do |exception, _locale, _key, _options|
    raise exception.is_a?(I18n::MissingTranslation) ? exception.to_exception : exception
  end
end
