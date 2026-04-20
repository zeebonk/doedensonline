require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  Bundler.require(*Rails.groups(:assets => %w(development test)))
end

module DoedensOnline
  class Application < Rails::Application
    config.encoding = 'utf-8'
    config.time_zone = 'UTC'

    config.filter_parameters += [:password]

    # The legacy app serves all CSS/JS straight out of public/, so the asset
    # pipeline is intentionally disabled to keep the upgrade minimal.
    config.assets.enabled = false
  end
end
