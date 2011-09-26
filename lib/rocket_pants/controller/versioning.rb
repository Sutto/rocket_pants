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
    
    module InstanceMethods
      
      protected
      
      def version
        @version ||= begin
          Integer(params[:version])
        rescue ArgumentError
          nil
        end
      end
      
      def verify_api_version
        error! :invalid_version unless version.present? && _version_range.include?(version)
      end
      
    end
    
  end
end