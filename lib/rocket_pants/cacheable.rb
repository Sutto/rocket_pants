module RocketPants
  module Cacheable
    extend ActiveSupport::Concern
    
    included do
      after_save    :record_cache!
      after_destroy :expire_cache!
    end
    
    module InstanceMethods
      
      def record_cache!
        RocketPants::Caching.record self
      end
      
      def remove_cache!
        RocketPants::Caching.remove self
      end
      
    end
    
  end
end