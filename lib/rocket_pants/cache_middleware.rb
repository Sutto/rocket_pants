module RocketPants
  class CacheMiddleware
    
    NOT_MODIFIED = [304, {}, []].freeze
    
    def initialize(app)
      @app = app
    end
    
    def call(env)
      dup._call env
    end
    
    def _call(env)
      @env = env
      if has_valid_etag?
        NOT_MODIFIED
      else
        @app.call env
      end
    end
    
    private
    
    def has_valid_etag?
      etag = request.etag
      return false if etag.blank?
      cache_key, value = extract_cache_key_and_value etag
      fresh? cache_key, value
    end
    
    def extract_cache_key_and_value(etag)
      etag.to_s.split(":", 2)
    end
    
    def fresh?(key, value)
      cached_value = RocketPants.cache[key.to_s]
      cached_value.present? && cached_value == value 
    end
    
    def request
      @_request ||= ActionDispatch::Request.new(@env)
    end
    
  end
end