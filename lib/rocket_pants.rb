require 'active_support/all'
require 'action_dispatch'
require 'action_dispatch/routing'
require 'action_controller'

module RocketPants
  require 'rocket_pants/exceptions'
  
  # Set up the routing in advance.
  require 'rocket_pants/routing'
  ActionDispatch::Routing::Mapper.send :include, RocketPants::Routing
  
  require 'rocket_pants/railtie' if defined?(Rails::Railtie)
  autoload :Base, 'rocket_pants/base'
  
  autoload :TestHelper,    'rocket_pants/test_helper'
  autoload :RSpecMatchers, 'rocket_pants/rspec_matchers'
  
end