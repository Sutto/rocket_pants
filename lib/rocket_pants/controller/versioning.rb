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
        begin
          version = remove_prefix_from_version params[:version]
          @version = version.presence && Integer(version)
        rescue ArgumentError
          nil
        end
      end
      @version
    end

    def verify_api_version
      error! :invalid_version unless version.present? && _version_range.include?(version)
    end

    def remove_prefix_from_version(version)
      if version.is_a?(String)
        version[/(\d+)/, 1]
      else
        version
      end
    end

  end
end
