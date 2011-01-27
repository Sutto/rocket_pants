module I18nSpecHelper
  
  def with_translations(*args)
    translations = args.extract_options!
    locale = (args.shift || I18n.locale).to_sym
    I18n.backend.store_translations locale, translations
    yield
  ensure
    I18n.reload!
  end
  
end