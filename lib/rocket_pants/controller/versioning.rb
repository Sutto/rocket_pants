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
          symbolized_path_params = request.path_parameters.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
          version = extract_version_string_with_prefix params[:version], symbolized_path_params[:rp_prefix]
          version.presence && Integer(version)
        rescue ArgumentError
          nil
        end
      end
      @version
    end

    def verify_api_version
      error! :invalid_version unless version.present? && _version_range.include?(version)
    end

    def extract_version_string_with_prefix(version, prefix)
      if version && prefix.is_a?(Hash)
        # We need to strip the text from the prefix.
        prefix_regexp = /^#{prefix[:text]}/
        version = version.to_s
        if prefix[:required] && version !~ prefix_regexp
          raise ArgumentError, "You required the route version prefix #{prefix[:text]}, but not was given."
        end
        version.gsub prefix_regexp, ''
      else
        # Otherwise, return it intact.
        version
      end
    end

  end
end
