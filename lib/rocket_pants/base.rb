require 'rocket_pants/exceptions'

module RocketPants
  
  autoload :ErrorHandling,   'rocket_pants/controller/error_handling'
  autoload :Respondable,     'rocket_pants/controller/respondable'
  autoload :Versioning,      'rocket_pants/controller/versioning'
  autoload :Instrumentation, 'rocket_pants/controller/instrumentation'
  
  class Base < ActionController::Metal
    abstract!
    
    MODULES = [
      ActionController::HideActions,
      ActionController::UrlFor,
      ActionController::Redirecting,
      ActionController::ConditionalGet,
      ActionController::RackDelegation,
      ActionController::RecordIdentifier,
      Respondable,
      Versioning,
      Instrumentation,
      # Include earliest as possible in the request.
      AbstractController::Callbacks,
      ActionController::Rescue,
      ErrorHandling
    ]
    
    MODULES.each do |mixin|
      include mixin
    end
    
    # Bug fix for rails - include compatibility.
    config_accessor :protected_instance_variables
    self.protected_instance_variables = %w(@assigns @performed_redirect @performed_render
      @variables_added @request_origin @url @parent_controller @action_name
      @before_filter_chain_aborted @_headers @_params @_response)

    ActiveSupport.run_load_hooks(:rocket_pants, self)
    
  end
end