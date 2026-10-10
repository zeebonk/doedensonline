DoedensOnline::Application.configure do
  config.cache_classes = true

  config.eager_load = true

  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  config.public_file_server.enabled = true

  config.hosts = ['doedensonline.nl']
  config.assume_ssl = true

  config.assets.js_compressor = :terser
  config.assets.compile = false
  config.assets.digest = true

  config.i18n.fallbacks = true

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
  config.action_mailer.default_url_options = { host: 'doedensonline.nl' }

  config.active_support.deprecation = :notify

  config.active_record.dump_schema_after_migration = false
end
