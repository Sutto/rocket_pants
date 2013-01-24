module RocketPants
  class Railtie < Rails::Railtie

    config.rocket_pants                     = ActiveSupport::OrderedOptions.new
    config.rocket_pants.use_caching         = nil
    config.rocket_pants.header_metadata     = nil
    config.rocket_pants.pass_through_errors = nil
    config.rocket_pants.pass_through_errors = nil

    config.i18n.railties_load_path << File.expand_path('../locale/en.yml', __FILE__)

    initializer "rocket_pants.logger" do
      ActiveSupport.on_load(:rocket_pants) { self.logger ||= Rails.logger }
    end

    initializer "rocket_pants.configuration" do |app|
      rp_config                          = app.config.rocket_pants
      rp_config.use_caching              = Rails.env.production? if rp_config.use_caching.nil?
      RocketPants.caching_enabled        = rp_config.use_caching
      RocketPants.header_metadata        = rp_config.header_metadata unless rp_config.header_metadata.nil?
      RocketPants.serializers_enabled    = rp_config.serializers_enabled unless rp_config.serializers_enabled.nil?
      RocketPants.show_exception_message = rp_config.show_exception_message unless rp_config.show_exception_message.nil?
      RocketPants.pass_through_errors    = rp_config.pass_through_errors unless rp_config.pass_through_errors.nil?
      # Set the rocket pants cache if present.
      RocketPants.cache = rp_config.cache if rp_config.cache
    end

    initializer "rocket_pants.url_helpers" do |app|
      ActiveSupport.on_load(:rocket_pants) do
        include app.routes.url_helpers
      end
    end

    initializer "rocket_pants.setup_testing" do |app|
      ActiveSupport.on_load(:rocket_pants) do
        include ActionController::Testing if Rails.env.test?
      end
    end

    initializer "rocket_pants.setup_caching" do |app|
      if RocketPants.caching_enabled?
        app.middleware.insert 'Rack::Runtime', RocketPants::CacheMiddleware
      end
    end

    initializer "rocket_pants.setup_activerecord" do
      if defined?(ActiveRecord)
        require 'rocket_pants/active_record'
      end
    end

    rake_tasks do
      load "rocket_pants/tasks/rocket_pants.rake"
    end

  end
end