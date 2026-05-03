unless Rails.env.production?
  I18n.exception_handler = lambda do |exception, _locale, _key, _options|
    raise exception.is_a?(I18n::MissingTranslation) ? exception.to_exception : exception
  end
end
