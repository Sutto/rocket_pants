require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'

require 'rocket_pants/errors'

require 'api_smith'
require 'will_paginate/collection'

module RocketPants
  # Implements a generalised base for building clients on top of
  # the rocket pants controller. This automatically unpacks the API
  # into the correct response types, handles errors (using the same error registry
  # as the server) and in general makes it simpler to implement api clients.
  #
  # @example A versioned api client
  #   class MyApiClient < RocketPants::Client
  #
  #     class Profile < APISmith::Smash
  #       property :name
  #       property :email
  #     end
  #
  #     version 1
  #     base_uri "http://api.example.com/"
  #
  #     def profile
  #       get 'profile', :transformer => Profile
  #     end
  #   end
  #
  class Client < APISmith::Base
    
    class_attribute :_version, :_actual_endpoint
    
    class << self
      
      # @overload version
      #   @return [Integer] the current API version number for this client
      # @overload version(number)
      #   Sets a variable noting what version of the api the client uses and updates
      #   the endpoint to prefix it with the given version number.
      #   @param [Integer] number the version of the api to process.
      def version(number = nil)
        if number.nil?
          _version
        else
          self._version = number
          endpoint _actual_endpoint
          number
        end
      end
      
      alias _original_endpoint endpoint

      # Sets the endpoint url, taking into account the version number as a
      # prefix if present.
      def endpoint(path)
        self._actual_endpoint = path
        _original_endpoint File.join(*[_version, path].compact.map(&:to_s))
      end
      
    end
    
    # Initializes a new client, optionally setting up the host for this client.
    # @param [Hash] options general client options
    # @option options [String] :api_host the overriden base_uri host for this client instance.
    def initialize(options = {})
      super
      # Setup the base uri if passed in to the client.
      if options[:api_host].present?
        add_request_options! :base_uri => HTTParty.normalize_base_uri(options[:api_host])
      end
    end
    
    private
    
    # Give a response hash from the api, will transform it into
    # the correct data type.
    # @param [Hash] response the incoming response
    # @param [hash] options any options to pass through for transformation
    # @return [Object] the transformed response.
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
    
    # Returns an API response wrapped in a will_paginate collection
    # using the pagination key in the response container to set up
    # the current number of total entries and page details.
    # @param [Array<Object>] objects the actual response contents
    # @param [Hash{String => Object}] The response container
    # @option container [Hash] "pagination" the pagination data to use.
    def paginated_response(objects, container)
      pagination = container.delete("pagination")
      WillPaginate::Collection.create(pagination["current"], pagination["per_page"]) do |collection|
        collection.replace objects
        collection.total_entries = pagination["count"]
      end
    end
    
    # Finds and uses the transformer for a given incoming object to
    # unpack it into a useful data type.
    # @param [Hash, Array<Hash>] object the response object to unpack
    # @param [Hash] options the unpacking options
    # @option options [Hash] :transformer,:as the transformer to use
    # @return The transformed data or the data itself when no transformer is specified.
    def unpack(object, options = {})
      transformer = options[:transformer] || options[:as]
      transformer ? transformer.call(object) : object
    end
    
    # Processes a given response to check for the presence of an error,
    # either by the response not being a hash (e.g. it is returning HTML instead
    # JSON or HTTParty couldn't parse the response).
    # @param [Hash, Object] response the response to check errors on
    # @raise [RocketPants::Error] a generic error when the type is wrong, or a registered error subclass otherwise.
    def check_response_errors(response)
      if !response.is_a?(Hash)
        raise RocketPants::Error, "The response from the server was not in a supported format."
      elsif response.has_key?("error")
        klass = RocketPants::Errors[response["error"]] || RocketPants::Error

        error_messages = if response.has_key?("messages")
          [response["messages"], response["error_description"]]
        else
          response["error_description"]
        end

        raise klass.new(*error_messages)
      end
    end
    
  end
end