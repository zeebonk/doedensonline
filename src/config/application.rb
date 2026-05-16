require File.expand_path('boot', __dir__)

require 'rails/all'

Bundler.require(*Rails.groups) if defined?(Bundler)

module DoedensOnline
  class Application < Rails::Application
    config.encoding = 'utf-8'
    config.time_zone = 'Amsterdam'
    config.i18n.default_locale = :nl

    config.filter_parameters += [:password]

    config.assets.enabled = true

    config.active_record.raise_in_transactional_callbacks = true
  end
end
