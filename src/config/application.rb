require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)

module DoedensOnline
  class Application < Rails::Application
    config.load_defaults 5.1

    config.encoding = 'utf-8'
    config.time_zone = 'Amsterdam'
    config.i18n.default_locale = :nl

    config.filter_parameters += [:password]

    config.assets.enabled = true
  end
end
