require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  Bundler.require(*Rails.groups(assets: %w(development test)))
end

module DoedensOnline
  class Application < Rails::Application
    config.encoding = 'utf-8'
    config.time_zone = 'Amsterdam'
    config.i18n.default_locale = :nl

    config.filter_parameters += [:password]

    config.assets.enabled = true
    config.assets.precompile += %w(
      main.css
      home.css
      photo_albums.css
      settings.css
      colorbox.css
      ie6.css
      ie7.css
      scaffold.css
      load-tiny-mce.js
      jquery-1.4.2.min.js
      colorbox/jquery.colorbox-min.js
      test.js
    )
  end
end
