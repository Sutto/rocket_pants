module RocketPants
  class Railtie < Rails::Railtie
    
    config.rocket_pants = ActiveSupport::OrderedOptions.new
    config.rocket_pants.use_caching = nil
    
    config.i18n.railties_load_path << File.expand_path('../locale/en.yml', __FILE__)
    
    initializer "rocket_pants.logger" do
      ActiveSupport.on_load(:rocket_pants) { self.logger ||= Rails.logger }
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
      rp_config = app.config.rocket_pants
      rp_config.use_caching = Rails.env.production? if rp_config.use_caching.nil?
      RocketPants.caching_enabled = rp_config.use_caching
      if RocketPants.caching_enabled?
        app.middleware.insert 'Rack::Runtime', RocketPants::CacheMiddleware
      end
    end

  end
end