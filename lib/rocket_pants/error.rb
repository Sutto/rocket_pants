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
  
end
