require 'hashie/mash'

module RocketPants
  module TestHelper
    extend ActiveSupport::Concern

    included do
      require 'action_controller/test_case'

      # Extend the response on first include.
      class_attribute :_default_version
      unless ActionController::TestResponse < ResponseHelper
        ActionController::TestResponse.send :include, ResponseHelper
      end

      unless ActionDispatch::TestResponse < ResponseHelper
        ActionDispatch::TestResponse.send :include, ResponseHelper
      end
    end

    module ResponseHelper

      def recycle_cached_body!
        @_parsed_body = @_decoded_body = nil
      end

      def parsed_body
        @_parsed_body ||= begin
          ActiveSupport::JSON.decode(body)
        rescue StandardError => e
          nil
        end
      end

      def decoded_body
        @_decoded_body ||= begin
          decoded = parsed_body
          if decoded.is_a?(Hash)
            Hashie::Mash.new(decoded)
          else
            decoded
          end
        end
      end

    end

    module ClassMethods

      def default_version(value)
        self._default_version = value
      end

    end

    def decoded_response
      value = response.decoded_body.try(:response)
    end

    def decoded_pagination
      response.decoded_body.try :pagination
    end

    def decoded_count
      response.decoded_body[:count]
    end

    def decoded_error_class
      error = response.decoded_body.try :error
      error.presence && RocketPants::Errors[error]
    end

    # RSpec matcher foo.

    def have_decoded_response(value)
      response = normalise_value(value)
    end

    protected

    def insert_action_controller_testing_into_base
      if defined?(ActionController::Testing)
        unless RocketPants::Base < ActionController::Testing
          RocketPants::Base.class_eval do
            include ActionController::Testing
          end
        end
      end
    end

    # Like process, but automatically adds the api version.
    def process(action, *args)

      insert_action_controller_testing_into_base

      # Rails 4 changes the method signature. In rails 3, parameters is the first argument.
      # In Rails 4, it's the second.
      if args.first.is_a?(String)
        parameters = (args[1] ||= {})
      else
        parameters = (args[0] ||= {})
      end

      response.recycle_cached_body!

      if _default_version.present? && parameters[:version].blank? && parameters['version'].blank?
        parameters[:version] = _default_version
      end

      super action, *args
    end

    def normalise_value(value)
      if value.is_a?(Hash)
        value.inject({}) do |acc, (k, v)|
          acc[k.to_s] = normalise_value(v)
          acc
        end
      elsif value.is_a?(Array)
        value.map { |v| normalise_value v }
      else
        value
      end
    end

  end
end
