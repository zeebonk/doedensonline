DoedensOnline::Application.configure do
  config.cache_classes = false

  config.eager_load = false

  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.assets.debug = true
  config.assets.raise_runtime_errors = true

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("DO_SMTP_HOST", nil),
    port: 587,
    user_name: ENV.fetch("DO_SMTP_USERNAME", nil),
    password: ENV.fetch("DO_SMTP_PASSWORD", nil),
    authentication: :plain,
    enable_starttls_auto: true,
    domain: 'doedensonline.nl'
  }
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: 'dev.doedensonline.nl' }

  config.active_support.deprecation = :log

  config.active_record.migration_error = :page_load

  config.log_level = :debug
end
