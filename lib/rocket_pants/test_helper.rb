require 'hashie/mash'

module RocketPants
  module TestHelper
    extend ActiveSupport::Concern

    included do
      # Extend the response on first include.
      class_attribute :_default_version
      unless ActionController::TestResponse < ResponseHelper
        ActionController::TestResponse.send :include, ResponseHelper
      end
    end

    module ResponseHelper

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

    module InstanceMethods

      def decoded_response
        value = response.decoded_body.try(:response)
      end

      def decoded_pagination
        response.decoded_body.try :pagination
      end

      def decoded_count
        response.decoded_body.try :count
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

      # Like process, but automatically adds the api version.
      def process(action, parameters = nil, session = nil, flash = nil, http_method = 'GET')
        parameters ||= {}
        if _default_version.present? && parameters[:version].blank? && parameters['version'].blank?
          parameters[:version] = _default_version
        end
        super
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
end