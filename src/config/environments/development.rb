DoedensOnline::Application.configure do
  config.cache_classes = false

  config.eager_load = false

  config.i18n.raise_on_missing_translations = true

  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.action_controller.raise_on_missing_callback_actions = true
  config.action_dispatch.verbose_redirect_logs = true

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

  config.hosts << 'dev.doedensonline.nl'

  config.active_support.deprecation = :log

  config.active_record.migration_error = :page_load

  config.log_level = :debug

  # The dev server runs in development mode; log to STDOUT there like
  # production does. Locally, logs keep going to log/development.log.
  if ENV['RAILS_LOG_TO_STDOUT'].present?
    config.logger = ActiveSupport::TaggedLogging.logger($stdout)
    config.log_tags = [:request_id]
  end
end
