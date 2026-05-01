require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  Bundler.require(*Rails.groups)
end

module DoedensOnline
  class Application < Rails::Application
    config.encoding = 'utf-8'
    config.time_zone = 'Amsterdam'
    config.i18n.default_locale = :nl

    config.filter_parameters += [:password]

    config.assets.enabled = true
  end
end
