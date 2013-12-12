require 'rocket_pants/errors'
require 'rails-api'

module RocketPants

  module API
    extend ActiveSupport::Concern

    MODULES = [
      UrlFor,
      Respondable,
      HeaderMetadata,
      Linking,
      Versioning,
      Caching,
      ErrorHandling,
      Rescuable,
      JSONP,
      StrongParameters,
      Instrumentation,
      ActionController::HttpAuthentication::Basic::ControllerMethods,
      ActionController::HttpAuthentication::Digest::ControllerMethods,
      ActionController::HttpAuthentication::Token::ControllerMethods
    ].compact

    # If possible, include the Rails controller methods in Airbrake to make it useful.
    begin
      require 'airbrake'
      require 'airbrake/rails/controller_methods'
      MODULES << Airbrake::Rails::ControllerMethods
    rescue LoadError => e
    end

    # If possible, include Honeybadger methods in the Rails controller
    begin
      require 'honeybadger'
      require 'honeybadger/rails/controller_methods'
      MODULES << Honeybadger::Rails::ControllerMethods
    rescue LoadError => e
    end

    MODULES.each do |mixin|
      include mixin
    end

  end

  class Base < ActionController::API
    abstract!
    include API
  end

end
