require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
# require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require 'action_mailbox/engine'
# require 'action_text/engine'
require 'action_view/railtie'
# require 'action_cable/engine'
require 'rails/test_unit/railtie'

Bundler.require(*Rails.groups)

module DoedensOnline
  class Application < Rails::Application
    config.load_defaults 8.1

    config.encoding = 'utf-8'
    config.time_zone = 'Amsterdam'
    config.i18n.default_locale = :nl

    config.filter_parameters += %i[
      passw email secret token _key crypt salt certificate otp ssn cvv cvc
    ]

    config.logger = ActiveSupport::TaggedLogging.logger($stdout)
    config.log_tags = [:request_id]

    config.silence_healthcheck_path = '/up'
  end
end
