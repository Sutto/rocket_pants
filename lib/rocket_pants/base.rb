require 'rocket_pants/errors'

module RocketPants

  class Base < ActionController::Metal

    abstract!

    MODULES = [
      ActionController::HideActions,
      ActionController::UrlFor,
      ActionController::Redirecting,
      ActionController::ConditionalGet,
      ActionController::RackDelegation,
      ActionController::RecordIdentifier,
      ActionController::HttpAuthentication::Basic::ControllerMethods,
      ActionController::HttpAuthentication::Digest::ControllerMethods,
      ActionController::HttpAuthentication::Token::ControllerMethods,
      UrlFor,
      Respondable,
      HeaderMetadata,
      Linking,
      Versioning,
      Instrumentation,
      Caching,
      # Include earliest as possible in the request.
      AbstractController::Callbacks,
      ActionController::Rescue,
      ErrorHandling,
      Rescuable,
      Presenter,
      JSONP
      # FormatVerification # TODO: Implement Format Verification
    ].compact

    # If possible, include the Rails controller methods in Airbrake to make it useful.
    begin
      require 'airbrake'
      require 'airbrake/rails/controller_methods'
      MODULES << Airbrake::Rails::ControllerMethods
    rescue LoadError => e
    end

    MODULES.each do |mixin|
      include mixin
    end

    # Bug fix for rails - include compatibility.
    config_accessor :protected_instance_variables
    self.protected_instance_variables = %w(@assigns @performed_redirect @performed_render
      @variables_added @request_origin @url @parent_controller @action_name
      @before_filter_chain_aborted @_headers @_params @_response)

    ActiveSupport.run_load_hooks(:rocket_pants, self)

    # Methods for integration purposes.
    def self.helper_method(*); end

  end
end