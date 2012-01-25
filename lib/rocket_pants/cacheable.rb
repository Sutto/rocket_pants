module RocketPants
  module Cacheable
    extend ActiveSupport::Concern
    
    included do
      after_save    :record_cache! if respond_to?(:after_save)
      after_destroy :remove_cache! if respond_to?(:after_destroy)
    end
    
    def record_cache!
      RocketPants::Caching.record self
    end
    
    def remove_cache!
      RocketPants::Caching.remove self
    end
    
  end
end