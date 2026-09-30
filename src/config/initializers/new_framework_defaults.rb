# Preserve the Rails 4.2 behavior during the Rails 5.0 upgrade. These settings
# can be enabled individually after the application has been verified in
# production.
Rails.application.config.action_controller.raise_on_unfiltered_parameters = true
Rails.application.config.active_record.belongs_to_required_by_default = false
Rails.application.config.action_controller.per_form_csrf_tokens = false
Rails.application.config.action_controller.forgery_protection_origin_check = false
Rails.application.config.action_mailer.perform_caching = false
ActiveSupport.to_time_preserves_timezone = false
ActiveSupport.halt_callback_chains_on_return_false = true
