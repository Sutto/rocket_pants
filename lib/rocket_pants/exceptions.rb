module RocketPants
  
  # Represents the standard error type as defined by the API.
  # RocketPants::Error instances will be caught and automatically rendered as JSON
  # by the controller during processing.
  class Error < StandardError
    
    # @overload error_name
    #   Returns the error name for this error class, defaulting to
    #   the class name underscorized minus _error.
    #   @return [Symbol] the given errors name.
    # @overload error_name(value)
    #   Sets the error name for the current class.
    #   @param [#to_sym] the name of this error.
    def self.error_name(value = nil)
      if value.nil?
        @name ||= name.underscore.split("/").last.sub(/_error$/, '').to_sym
      else
        @name = (value.presence && value.to_sym)
      end
    end
    
    # @overload http_status
    #   Returns the http status code of this error, defaulting to 400 (Bad Request).
    # @overload http_status(value)
    #   Sets the http status code for this error to a given symbol / integer.
    #   @param value [String, Fixnum] value the new status code.
    def self.http_status(value = nil)
      if value.nil?
        @http_status ||= 400
      else
        @http_status = (value.presence && value)
      end
    end
    
    # Gets the name of this error from the class.
    def error_name
      self.class.error_name
    end
    
    # Gets the http status of this error from the class.
    def http_status
      self.class.http_status
    end
    
    # Setter for optional data about this error, used for translation.
    attr_writer :context
    
    # Gets the context for this error, defaulting to nil.
    # @return [Hash] the context for this param.
    def context
      @context ||= {}
    end
    
    error_name :unknown

  end
  
  # A simple map of data about errors that the rocket pants system can handle.
  class Errors
    
    @@errors = {}
    
    # Returns a hash of all known errors, keyed by their error name.
    # @return [Hash{Symbol => RocketPants::Error}] the hash of known errors.
    def self.all
      @@errors.dup
    end
    
    # Looks up a specific error from the given name, returning nil if none are found.
    # @param [#to_sym] name the name of the error to look up.
    # @return [Error, nil] the error class if found, otherwise nil.
    def self.[](name)
      @@errors[name.to_sym]
    end
    
    # Adds a given Error class in the list of all errors, making it suitable
    # for lookup via [].
    # @see Errors[]
    # @param [Error] error the error to register.
    def self.add(error)
      @@errors[error.error_name] = error
    end
    
    # Creates an error class to represent a given error state.
    # @param [Symbol] name the name of the given error
    # @param [Hash] options the options used to create the error class.
    # @option options [Symbol] :class_name the name of the class (under `RocketPants`), defaulting to the classified name.
    # @option options [Symbol] :error_name the name of the error, defaulting to the name parameter.
    # @option options [Symbol] :http_status the status code for the given error, doing nothing if absent.
    # @example Adding a RocketPants::NinjasUnavailable class w/ `:service_unavailable` as the status code:
    #   register! :ninjas_unavailable, :http_status => :service_unavailable
    def self.register!(name, options = {})
      klass_name = (options[:class_name] || name.to_s.classify).to_sym
      klass = Class.new(Error)
      klass.error_name(options[:error_name] || name.to_s.underscore)
      klass.http_status(options[:http_status]) if options[:http_status].present?
      (options[:under] || RocketPants).const_set klass_name, klass
      add klass
      klass
    end
    
    # The default set of exceptions.
    register! :throttled,       :http_status => :service_unavailable
    register! :unauthenticated, :http_status => :unauthorized
    register! :invalid_version, :http_status => :not_found
    register! :not_implemented, :http_status => :service_unavailable
    register! :not_found,       :http_status => :not_found
    
  end
  
end
