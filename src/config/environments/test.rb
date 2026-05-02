DoedensOnline::Application.configure do
  config.cache_classes = true

  config.serve_static_assets = true

  config.assets.compress = true
  config.assets.compile = true
  config.assets.digest = true

  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.action_dispatch.show_exceptions = false

  config.action_controller.allow_forgery_protection = false

  config.action_mailer.delivery_method = :test

  config.active_support.deprecation = :stderr

  config.active_record.mass_assignment_sanitizer = :strict

  I18n.exception_handler = lambda do |exception, _locale, _key, _options|
    raise exception.is_a?(I18n::MissingTranslation) ? exception.to_exception : exception
  end
end
