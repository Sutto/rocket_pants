module RocketPants
  # This mixin implements easy JSONP support in your application,
  # making it easy for developers to support it in their response.
  module JSONP
    extend ActiveSupport::Concern

    included do
      class_attribute :_jsonp_parameter
      self._jsonp_parameter = :callback
    end

    module ClassMethods

      # Marks the current controller as supporting JSONP-style responses.
      # @parameter [Hash{Symbol => Object}] options An optional hash of options to configure the callback.
      #   Non-specified options are passed to the filter call.
      # @option options [Symbol,String] :parameter If set, specifies the param name of the callback. Defaults to :callback.
      # @option options [true, false] :enable Whether to enable JSONP. true by default.
      def jsonp(options = {})
        enable = options.delete(:enable) { true }
        param  = options.delete(:parameter).try(:to_sym)
        if enable
          after_filter :wrap_response_in_jsonp, {:if => :jsonp_is_possible?}.reverse_merge(options)
          self._jsonp_parameter = param if param
        else
          skip_after_filter :wrap_response_in_jsonp, options
        end
      end

    end

    private

    def jsonp_is_possible?
      request.get? && response.content_type == "application/json" && jsonp_parameter.present?
    end

    def jsonp_parameter
      params[_jsonp_parameter]
    end

    def wrap_response_in_jsonp
      # Finally, set up the callback using the JSONP parameter.
      response.content_type     = 'application/javascript'
      response.body             = "#{jsonp_parameter}(#{response.body});"
      headers['Content-Length'] = (response.body.bytesize).to_s
    end

  end
end
