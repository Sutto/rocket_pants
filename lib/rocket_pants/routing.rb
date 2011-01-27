require 'ruby-debug'

module RocketPants
  module Routing
    
    class VersionConstraint
      
      def initialize(versions)
        @versions = versions
      end
      
      def matches?(req)
        @versions.include? req.path_parameters[:version]
      end
      
    end
    
    # Scopes a set of given api routes, allowing for option versions.
    # @param [Hash] options options to pass through to the route e.g. `:module`.
    # @option options [Array<Integer>, Integer] :versions the versions to support
    # @option options [Array<Integer>, Integer] :version the single version to support
    # @raise [ArgumentError] raised when the version isn't provided.
    def rocket_pants(options = {}, &blk)
      versions = (Array(options[:versions]) + Array(options[:version])).flatten.map(&:to_s)
      raise ArgumentError, 'please provider atleast one version' if versions.empty?
      options = options.deep_merge({
        :constraints => VersionConstraint.new(versions),
        :path        => ':version'
      })
      scope options, &blk
    end
    
  end
end