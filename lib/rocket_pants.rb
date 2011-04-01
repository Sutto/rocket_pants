require 'active_support/all'
require 'action_dispatch'
require 'action_dispatch/routing'
require 'action_controller'

require 'moneta'
require 'moneta/memory'

module RocketPants
  require 'rocket_pants/exceptions'

  # Set up the routing in advance.
  require 'rocket_pants/routing'
  ActionDispatch::Routing::Mapper.send :include, RocketPants::Routing

  require 'rocket_pants/railtie' if defined?(Rails::Railtie)

  # Extra parts of RocketPants.
  autoload :Base,            'rocket_pants/base'
  autoload :Client,          'rocket_pants/client'
  autoload :Cacheable,       'rocket_pants/cacheable'
  autoload :CacheMiddleware, 'rocket_pants/cache_middleware'

  # Helpers for various testing frameworks.
  autoload :TestHelper,      'rocket_pants/test_helper'
  autoload :RSpecMatchers,   'rocket_pants/rspec_matchers'

  mattr_accessor :caching_enabled
  self.caching_enabled = false

  mattr_writer :cache

  class << self
    alias caching_enabled? caching_enabled

    def cache
      @@cache ||= Moneta::Memory.new
    end
  end

end