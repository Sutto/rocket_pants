module RocketPants
  class CacheMiddleware
    
    NOT_MODIFIED = [304, {}, []]
    
    def initialize(app)
      @app = app
    end
    
    def call(env)
      dup._call env
    end
    
    def _call(env)
      @env = env
      if has_valid_etag?
        debug "Cache key is valid, returning not modified response."
        NOT_MODIFIED.dup
      else
        @app.call env
      end
    end
    
    private
    
    def has_valid_etag?
      return false if (etags = request_etags).blank?
      debug ""
      etags.any? do |etag|
        cache_key, value = extract_cache_key_and_value etag
        debug "Checking cache key #{cache_key} matches the value #{value}"
        fresh? cache_key, value
      end
    end
    
    def extract_cache_key_and_value(etag)
      etag.to_s.split(":", 2)
    end
    
    def fresh?(key, value)
      RocketPants.cache[key.to_s] == value
    end
    
    def request_etags
      stored = @env['HTTP_IF_NONE_MATCH']
      stored.present? && stored.to_s.scan(/"([^"]+)"/)
    end
    
    def debug(message)
      Rails.logger.debug message if defined?(Rails.logger)
    end

  end
end