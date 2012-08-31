require 'set'

module RocketPants
  module Routing

    class HeaderVersioningConstraint

      def initialize(versions)
        @versions = Set.new(versions)
      end

      def matches?(request)
        accept_header = request.headers['Accept']
        return if accept_header.blank?
        match = RocketPants.compiled_version_header_regexp.match(accept_header)
        match && @versions.include?(match[1])
      end

    end

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
      raise ArgumentError, 'please provide atleast one version' if versions.empty?
      if RocketPants.path_versioning?
        versions_regexp = /(#{versions.uniq.join("|")})/
        options = options.deep_merge({
          :constraints => {:version => versions_regexp},
          :path        => ':version',
          :defaults    => {:format => 'json'}
        })
      elsif RocketPants.header_versioning?
        options = options.deep_merge({
          :constraints => {:version => HeaderVersioningConstraint.new(versions)},
          :defaults    => {:format => 'json'}
        })
      else
        raise "Something's broken batman - Neither path or header versioning."
      end
      scope options, &blk
    end
    alias api rocket_pants

  end
end