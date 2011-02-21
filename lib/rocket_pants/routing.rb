module RocketPants
  module Routing

    # Scopes a set of given api routes, allowing for option versions.
    # @param [Hash] options options to pass through to the route e.g. `:module`.
    # @option options [Array<Integer>, Integer] :versions the versions to support
    # @option options [Array<Integer>, Integer] :version the single version to support
    # @raise [ArgumentError] raised when the version isn't provided.
    def rocket_pants(options = {}, &blk)
      versions = (Array(options.delete(:versions)) + Array(options.delete(:version))).flatten.map(&:to_s)
      versions.each do |version|
        raise ArgumentError, "Got invalid version: '#{version}'" unless version =~ /\A\d+\Z/
      end
      versions_regexp = /(#{versions.uniq.join("|")})/
      raise ArgumentError, 'please provide atleast one version' if versions.empty?
      options = options.deep_merge({
        :constraints => {:version => versions_regexp},
        :path        => ':version',
        :defaults    => {:format => 'json'}
      })
      scope options, &blk
    end
    alias api rocket_pants

  end
end