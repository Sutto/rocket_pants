require 'set'
require 'digest/md5'

module RocketPants
  # RocketPants::Caching adds unobtrusive support for automatic HTTP-level caching
  # to controllers built on Rocket Pants. It will automatically.
  module Caching
    extend ActiveSupport::Concern
    
    included do
      class_attribute :cached_actions, :caching_timeout, :caching_options
      self.caching_timeout     = 5.minutes
      self.cached_actions      = Set.new
      self.caching_options     = {:public => true}
    end
    
    class << self
          
      # Removes the cache record for a given object, making sure
      # It isn't contained in the Rocket Pants etag cache thus
      # ignoring it in incoming responses.
      # @param [Object] object what to remove from the cache
      def remove(object)
        RocketPants.cache.delete cache_key_for(object)
      end
    
      # Takes a given object and sets the stored etag in the Rocket Pants
      # etag key to have the correct value.
      #
      # Doing this means that on subsequent requests with caching enabled,
      # the request will be automatically recorded by the middleware and not
      # actually served.
      #
      # Please note that this expects the object has a cache_key method
      # defined that will return a string, useable for caching. If not,
      # it will use inspect which is a VERY VERY bad idea (and will likely
      # be removed in the near future).
      #
      # @param [#cache_key] object what to record in the cache
      def record(object, cache_key = cache_key_for(object))
        default_etag = object.inspect
        if object.respond_to?(:cache_key).presence && (ck = object.cache_key).present?
          default_etag = ck
        end
        generated_etag = Digest::MD5.hexdigest(default_etag)
        RocketPants.cache[cache_key] = generated_etag
      end
      
      # Given an object, returns the etag value to be used in
      # the response / etag header (prior to any more processing).
      # If the object isn't in the cache, we'll instead record
      # it and return the etag for it.
      # @param [#cache_key] object what to look up the etag for
      def etag_for(object)
        cache_key = cache_key_for(object)
        etag_value = RocketPants.cache[cache_key].presence || record(object, cache_key)
        "#{cache_key}:#{etag_value}"
      end
    
      # Returns the default cache key for a given object.
      # Note that when the object defines a rp_object_key method, it will
      # be used as the
      #
      # @param [Object, #rp_object_key] the object to find the cache key for.
      def cache_key_for(object)
        if object.respond_to?(:rp_object_key) && (ok = object.rp_object_key).present?
          Digest::MD5.hexdigest ok
        else
          suffix = (object.respond_to?(:new?) && object.new?) ? "new" : object.id
          Digest::MD5.hexdigest "#{object.class.name}/#{suffix}"
        end
      end
    
      def normalise_etag(identifier_or_object)
        %("#{identifier_or_object.to_s}")
      end
    
    end
    
    module ClassMethods
      
      # Sets up automatic etag and cache control headers for api resource
      # controllers using an after filter. Note that for the middleware
      # to actually be inserted, `RocketPants.enable_caching` needs to be
      # set to true.
      # @param [Symbol*] args a collection of action names to perform caching on.
      # @param [Hash] options options to configure caching
      # @option options [Integer, ActiveSupport::Duration] :cache_for the amount of
      #    time to cache timeout based actions for.
      # @example Setting up caching on a series of actions
      #   caches :index, :show
      # @example Setting up caching with options
      #   caches :index, :show, :cache_for => 3.minutes
      def caches(*args)
        options     = args.extract_options!
        self.cached_actions += Array.wrap(args).map(&:to_s).compact
        # Setup the time based caching.
        if options.has_key?(:cache_for)
          self.caching_timeout = options.delete(:cache_for)
        end
        # Merge in any caching options for other controllers.
        caching_options.merge!(options.delete(:caching_options) || {})
      end
      
    end
    
    def cache_action?(action = params[:action])
      RocketPants.caching_enabled? && cached_actions.include?(action)
    end
    
    def cache_response(resource, single_resource)
      # Add in the default options.
      response.cache_control.merge! caching_options
      # We need to set the etag based on the object when it is singular
      # Note that the object is responsible for clearing the etag cache.
      if single_resource
        response["ETag"] = Caching.normalise_etag Caching.etag_for(resource)
      # Otherwise, it's a collection and we need to use time based caching.
      else
        response.cache_control[:max_age] = caching_timeout
      end
    end
    
    # The callback use to automatically cache the current response object, using it's
    # cache key as a guide. For collections, instead of using an etag we'll use the request
    # path as a cache key and instead use a timeout.
    def post_process_exposed_object(resource, type, singular)
      super # Make sure we invoke the old hook.
      if cache_action?
        cache_response resource, singular
      end
    end
      
  end
end