module RocketPants
  module Versioning

    extend ActiveSupport::Concern

    included do
      class_attribute :_version_range
    end

    module ClassMethods

      def version(version)
        version = version..version if version.is_a?(Integer)
        self._version_range = version
        before_filter :verify_api_version
      end

    end

    protected

    def version
      if !instance_variable_defined?(:@version)
        @version = begin
          version = detected_version
          version.presence && Integer(version)
        rescue ArgumentError
          nil
        end
      end
      @version
    end

    # TODO: Consider using aliasing once configured.
    def detected_version
      if RocketPants.path_versioning?
        detected_param_version
      else
        detected_header_version
      end
    end

    def detected_param_version
      params[:version]
    end

    def detected_header_version
      request.headers['Accept'][RocketPants.compiled_version_header_regexp, 1].presence
    end

    def verify_api_version
      error! :invalid_version unless version.present? && _version_range.include?(version)
    end

  end
end