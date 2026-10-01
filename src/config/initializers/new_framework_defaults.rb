# Rails 5.0 framework defaults that are still held back on top of
# `config.load_defaults 5.1`. These settings can be enabled individually after
# the application has been verified in production.
Rails.application.config.active_record.belongs_to_required_by_default = false
Rails.application.config.action_controller.per_form_csrf_tokens = false
Rails.application.config.action_controller.forgery_protection_origin_check = false
Rails.application.config.action_mailer.perform_caching = false
ActiveSupport.to_time_preserves_timezone = false
