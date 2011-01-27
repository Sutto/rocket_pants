module RocketPants
  require 'rocket_pants/exceptions'
  require 'rocket_pants/routing'
  require 'rocket_pants/railtie' if defined?(Rails::Railtie)
  autoload :Base, 'rocket_pants/base'
end