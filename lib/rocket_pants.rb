require 'active_support/all'
require 'action_dispatch'
require 'action_dispatch/routing'
require 'action_controller'

require 'moneta'
require 'moneta/memory'

module RocketPants
  require 'rocket_pants/error'
  require 'rocket_pants/errors'

  # Set up the routing in advance.
  require 'rocket_pants/routing'
  ActionDispatch::Routing::Mapper.send :include, RocketPants::Routing

  require 'rocket_pants/railtie' if defined?(Rails::Railtie)

  # Extra parts of RocketPants.
  autoload :Base,            'rocket_pants/base'
  autoload :Client,          'rocket_pants/client'
  autoload :Cacheable,       'rocket_pants/cacheable'
  autoload :CacheMiddleware, 'rocket_pants/cache_middleware'

  # Model
  autoload :Presenter,        'rocket_pants/presenter'

  # Helpers for various testing frameworks.
  autoload :TestHelper,      'rocket_pants/test_helper'
  autoload :RSpecMatchers,   'rocket_pants/rspec_matchers'

  # Each of the controller mixins etc.
  autoload :Caching,            'rocket_pants/controller/caching'
  autoload :ErrorHandling,      'rocket_pants/controller/error_handling'
  autoload :Instrumentation,    'rocket_pants/controller/instrumentation'
  autoload :JSONP,              'rocket_pants/controller/jsonp'
  autoload :Rescuable,          'rocket_pants/controller/rescuable'
  autoload :Respondable,        'rocket_pants/controller/respondable'
  autoload :HeaderMetadata,     'rocket_pants/controller/header_metadata'
  autoload :Linking,            'rocket_pants/controller/linking'
  autoload :Versioning,         'rocket_pants/controller/versioning'
  autoload :FormatVerification, 'rocket_pants/controller/format_verification'
  autoload :UrlFor,             'rocket_pants/controller/url_for'

  mattr_accessor :caching_enabled, :header_metadata

  self.caching_enabled = false
  self.header_metadata = false

  mattr_writer :cache

  class << self
    alias caching_enabled? caching_enabled
    alias header_metadata? header_metadata

    def cache
      @@cache ||= Moneta::Memory.new
    end

    def env
      @@env ||= default_env
    end

    def env=(value)
      value = value.presence && ActiveSupport::StringInquirer.new(value)
      @@env = value
    end

    def default_env
      env = Rails.env.to_s if defined?(Rails.env)
      env ||= ENV['RAILS_ENV'].presence || ENV['RACK_ENV'].presence || "development"
      ActiveSupport::StringInquirer.new env
    end

    def default_pass_through_errors
      env.development? || env.test?
    end

    def pass_through_errors
      if defined?(@@pass_through_errors) && [true, false].include?(@@pass_through_errors)
        @@pass_through_errors
      else
        @@pass_through_errors = default_pass_through_errors
      end
    end
    alias pass_through_errors? pass_through_errors

    def pass_through_errors=(value)
      @@pass_through_errors = value
    end

  end

end