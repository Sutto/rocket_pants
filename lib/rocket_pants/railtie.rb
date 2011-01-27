module RocketPants
  class Railtie < Rails::Railtie
    
    config.rocket_pants = ActiveSupport::OrderedOptions.new
    
    initializer "rocket_pants.logger" do
      ActiveSupport.on_load(:rocket_pants) { self.logger ||= Rails.logger }
    end
    
    initializer "rocket_pants.set_configs" do |app|
      options = app.config.rocket_pants
      # Tell it how to load itself.
      ActiveSupport.on_load(:rocket_pants) do
        include app.routes.url_helpers
        options.each { |k,v| send("#{k}=", v) }
      end
    end
    
    initializer "rocket_pants.setup_testing" do |app|
      ActiveSupport.on_load(:rocket_pants) do
        include ActionController::Testing if Rails.env.test?
      end
    end

  end
end