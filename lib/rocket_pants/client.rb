require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/object/blank'

require 'api_smith'
require 'will_paginate/collection'

module RocketPants
  class Client < APISmith::Base
    
    class_attribute :_version, :_actual_endpoint
    
    class << self
      
      alias _original_endpoint endpoint
      
      def version(number = nil)
        number.nil? ? _version : (self._version = number)
        endpoint _actual_endpoint
      end
      
      def endpoint(path)
        self._actual_endpoint = path
        _original_endpoint File.join(*[_version, path].compact.map(&:to_s))
      end
      
    end
    
    def initialize(options = {})
      # Setup the base uri if passed in to the client.
      if options[:api_host].present?
        add_request_options! :base_uri => HTTParty.normalize_base_uri(options[:api_host])
      end
    end
    
    private
    
    # Give a response hash, will process it and unpack the
    # data into the correct data types and wrappers.
    def transform_response(response, options = {})
      # Now unpack the response into the data types.
      inner = response.delete("response")
      objects = unpack inner, options
      # Unpack pagination as a special case.
      if response.has_key?("pagination")
        paginated_response objects, response
      else
        objects
      end
    end
    
    # Returns an API response wrapped in a will_paginate collection.
    def paginated_response(objects, container)
      pagination = container.delete("pagination")
      WillPaginate::Collection.create(pagination["current"], pagination["per_page"]) do |collection|
        collection.replace objects
        collection.total_entries = pagination["count"]
      end
    end
    
    def unpack(object, options = {})
      transformer = options[:transformer] || options[:as]
      transformer ? transformer.call(object) : object
    end
    
    def check_response_errors(response)
      if !response.is_a?(Hash)
        raise RocketPants::Error, "The response from the server was not in a supported format."
      elsif response.has_key?("error")
        klass = RocketPants::Errors[response["error"]] || RocketPants::Error
        raise klass.new(response["error_description"])
      end
    end
    
  end
end